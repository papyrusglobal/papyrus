pragma solidity >=0.4.0 <0.6.0;


/// @author The Papyrus team.
/// @title Helper contract providing queue implementation.
/// @dev No storage data here because the contract is inherited.
contract QueueHelper {
    uint8 constant kQueueLen = 10;

    struct Queue {
        uint8 top;
        uint8 bottom;
        Entry[kQueueLen] entries;
    }

    struct Entry {
        uint224 stake;
        uint32 timestamp;
    }

    function push(Queue storage queue, Entry memory entry) internal {
        require(queue.entries[queue.top].timestamp == 0, "not enough slots");
        queue.entries[queue.top] = entry;
        advance(queue);
    }

    function pop(Queue storage queue) internal {
        require(size(queue) != 0, "no more slots");
        delete queue.entries[queue.bottom];
        queue.bottom = (queue.bottom + 1) % kQueueLen;
    }

    function head(Queue storage queue) view internal returns (Entry storage) {
        return queue.entries[queue.bottom];
    }

    function size(Queue storage queue) view internal returns (uint8) {
        if (queue.top == queue.bottom && queue.entries[queue.top].timestamp != 0) {
            return kQueueLen;
        } else if (queue.top >= queue.bottom) {
            return uint8(queue.top - queue.bottom);
        } else {
            return uint8(kQueueLen + queue.top - queue.bottom);
        }
    }

    function all(Queue storage queue) view internal returns (uint224[] memory stakes, uint32[] memory timestamps) {
        uint8 sz = size(queue);
        stakes = new uint224[](sz);
        timestamps = new uint32[](sz);
        uint j = queue.bottom;
        for(uint i = 0; i != sz; ++i) {
            stakes[i] = queue.entries[j].stake;
            timestamps[i] = queue.entries[j].timestamp;
            if (++j == kQueueLen) j = 0;
        }
    }

    function advance(Queue storage queue) private {
        queue.top = (queue.top + 1) % kQueueLen;
    }
}
