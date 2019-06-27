// Copyright 2015 The go-ethereum Authors
// This file is part of the go-ethereum library.
//
// The go-ethereum library is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// The go-ethereum library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with the go-ethereum library. If not, see <http://www.gnu.org/licenses/>.

package core

import (
	"encoding/hex"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/consensus"
	"github.com/ethereum/go-ethereum/consensus/misc"
	"github.com/ethereum/go-ethereum/core/state"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/core/vm"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/log"
	"github.com/ethereum/go-ethereum/params"
	"golang.org/x/crypto/sha3"
)

// StateProcessor is a basic Processor, which takes care of transitioning
// state from one point to another.
//
// StateProcessor implements Processor.
type StateProcessor struct {
	config *params.ChainConfig // Chain configuration options
	bc     *BlockChain         // Canonical block chain
	engine consensus.Engine    // Consensus engine used for block rewards
}

// NewStateProcessor initialises a new StateProcessor.
func NewStateProcessor(config *params.ChainConfig, bc *BlockChain, engine consensus.Engine) *StateProcessor {
	return &StateProcessor{
		config: config,
		bc:     bc,
		engine: engine,
	}
}

// VersionerAddress - address of the Versioner contract that locates current Bios contract.
var VersionerAddress = common.HexToAddress("0x0000000000000000000000000000000000000022")

func getBiosAddress(state vm.StateDB) common.Address {
	data := state.GetState(VersionerAddress, common.Hash{})
	var addr common.Address
	addr.SetBytes(data[:])
	return addr
}

// GetStaked returns currently staked value by the given address.
func GetStaked(sender common.Address, state vm.StateDB) big.Int {
	biosAddress := getBiosAddress(state)
	if biosAddress == (common.Address{}) {
		return *big.NewInt(0)
	}
	disposition := make([]byte, 64)
	copy(disposition[12:32], sender[:])
	hasher := sha3.NewLegacyKeccak256()
	hasher.Write(disposition)
	hash := hex.EncodeToString(hasher.Sum(nil))
	data := state.GetState(biosAddress, common.HexToHash(hash))
	return *new(big.Int).SetBytes(data[:])

}

// signersOffset is the offset of signers array in Bios contract storage
// space. Actually it is keccak256(abi.encode(1)) because signers array
// occupies slot 1.
var signersArrayOffset = common.HexToHash("b10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6").Big()
var signersLenOffset = common.HexToHash("0000000000000000000000000000000000000000000000000000000000000001")

// GetSigners fetches signers list from the Bios contract.
func GetSigners(state vm.StateDB) []common.Address {
	biosAddress := getBiosAddress(state)
	if biosAddress == (common.Address{}) {
		return nil
	}
	lenSlot := state.GetState(biosAddress, signersLenOffset)
	len := new(big.Int).SetBytes(lenSlot[:]).Uint64()
	signers := make([]common.Address, len)
	for i := range signers {
		addressSlot := state.GetState(
			biosAddress,
			common.BigToHash(new(big.Int).Add(signersArrayOffset, big.NewInt(int64(i)))))
		signers[i] = common.BytesToAddress(addressSlot[:])
	}
	return signers
}

var blocksInAMeltingPeriod = big.NewInt(24 * 60 * 60 / 3 * 3) // 3 days, block per 3 sec

// FetchLimit gets the current limit for the specified account. If the limit
// is not set yet, but the stake exists, calculates initial limit. If allowed
// (rw), sets the account limit to the value.
func FetchLimit(acc common.Address, state vm.StateDB, blockGasLimit uint64, rw bool) uint64 {
	biosAddress := getBiosAddress(state)
	if biosAddress == (common.Address{}) {
		return 0
	}
	limit := state.GetLimit(acc)
	totalStake := state.GetBalance(biosAddress)
	if limit == 0 && totalStake.Sign() == 1 {
		stake := GetStaked(acc, state)
		stakeGas := new(big.Int).Mul(&stake, big.NewInt(int64(blockGasLimit)))
		stakePeriod := new(big.Int).Mul(stakeGas, blocksInAMeltingPeriod)
		limit = new(big.Int).Div(stakePeriod, totalStake).Uint64()
		log.Warn("/// fetchLimit set", "limit", limit, "account", acc, "rw", rw,
			"stake", stake, "blockGasLimit", blockGasLimit)
		if rw {
			state.SetLimit(acc, limit)
		}
	}
	return limit
}

func checkStaked(tx *types.Transaction, state *state.StateDB, header *types.Header, config *params.ChainConfig) bool {
	biosAddress := getBiosAddress(state)
	if biosAddress == (common.Address{}) {
		log.Warn("/// All tx allowed")
		return true
	}
	if from := tx.To(); from != nil && *from == biosAddress {
		log.Warn("/// Bios tx allowed")
		return true
	}
	signer := types.MakeSigner(config, header.Number)
	sender, _ := types.Sender(signer, tx)
	limit := FetchLimit(sender, state, header.GasLimit, false)
	unmetered := limit != 0
	log.Warn("/// checkStaked", "block", header.Number, "unmetered", unmetered)
	return unmetered
}

// Process processes the state changes according to the Ethereum rules by running
// the transaction messages using the statedb and applying any rewards to both
// the processor (coinbase) and any included uncles.
//
// Process returns the receipts and logs accumulated during the process and
// returns the amount of gas that was used in the process. If any of the
// transactions failed to execute due to insufficient gas it will return an error.
func (p *StateProcessor) Process(block *types.Block, statedb *state.StateDB, cfg vm.Config) (types.Receipts, []*types.Log, uint64, error) {
	var (
		receipts types.Receipts
		usedGas  = new(uint64)
		header   = block.Header()
		allLogs  []*types.Log

		gp = new(GasPool).AddGas(block.GasLimit())
	)
	/// papyrus := p.engine.(*papyrus.Papyrus)
	/// papyrus.SetSigners(GetSigners(statedb))

	// Mutate the block and state according to any hard-fork specs
	if p.config.DAOForkSupport && p.config.DAOForkBlock != nil && p.config.DAOForkBlock.Cmp(block.Number()) == 0 {
		misc.ApplyDAOHardFork(statedb)
	}
	// Iterate over and process the individual transactions
	for i, tx := range block.Transactions() {
		statedb.Prepare(tx.Hash(), block.Hash(), i)
		tx.SetUnmetered(checkStaked(tx, statedb, header, p.config))
		receipt, _, err := ApplyTransaction(p.config, p.bc, nil, gp, statedb, header, tx, usedGas, cfg)
		if err != nil {
			return nil, nil, 0, err
		}
		receipts = append(receipts, receipt)
		allLogs = append(allLogs, receipt.Logs...)
	}
	// Finalize the block, applying any consensus engine specific extras (e.g. block rewards)
	p.engine.Finalize(p.bc, header, statedb, block.Transactions(), block.Uncles(), receipts)

	return receipts, allLogs, *usedGas, nil
}

// ApplyTransaction attempts to apply a transaction to the given state database
// and uses the input parameters for its environment. It returns the receipt
// for the transaction, gas used and an error if the transaction failed,
// indicating the block was invalid.
func ApplyTransaction(config *params.ChainConfig, bc ChainContext, author *common.Address, gp *GasPool, statedb *state.StateDB, header *types.Header, tx *types.Transaction, usedGas *uint64, cfg vm.Config) (*types.Receipt, uint64, error) {
	msg, err := tx.AsMessage(types.MakeSigner(config, header.Number))
	if err != nil {
		return nil, 0, err
	}
	// Create a new context to be used in the EVM environment
	context := NewEVMContext(msg, header, bc, author)
	// Create a new environment which holds all relevant information
	// about the transaction and calling mechanisms.
	vmenv := vm.NewEVM(context, statedb, config, cfg)
	// Apply the transaction to the current state (included in the env)
	_, gas, failed, err := ApplyMessage(vmenv, msg, gp)
	if err != nil {
		return nil, 0, err
	}
	// Update the state with pending changes
	var root []byte
	if config.IsByzantium(header.Number) {
		statedb.Finalise(true)
	} else {
		root = statedb.IntermediateRoot(config.IsEIP158(header.Number)).Bytes()
	}
	*usedGas += gas

	// Create a new receipt for the transaction, storing the intermediate root and gas used by the tx
	// based on the eip phase, we're passing whether the root touch-delete accounts.
	receipt := types.NewReceipt(root, failed, *usedGas)
	receipt.TxHash = tx.Hash()
	receipt.GasUsed = gas
	// if the transaction created a contract, store the creation address in the receipt.
	if msg.To() == nil {
		receipt.ContractAddress = crypto.CreateAddress(vmenv.Context.Origin, tx.Nonce())
	}
	// Set the receipt logs and create a bloom for filtering
	receipt.Logs = statedb.GetLogs(tx.Hash())
	receipt.Bloom = types.CreateBloom(types.Receipts{receipt})

	return receipt, gas, err
}
