// Copyright 2016 The papyrus Authors
// This file is part of the papyrus library.
//
// The papyrus library is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// The papyrus library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with the papyrus library. If not, see <http://www.gnu.org/licenses/>.

package api

import (
	"github.com/papyrusglobal/papyrus/swarm/network"
)

type Control struct {
	api  *API
	hive *network.Hive
}

func NewControl(api *API, hive *network.Hive) *Control {
	return &Control{api, hive}
}

//func (self *Control) BlockNetworkRead(on bool) {
//	self.hive.BlockNetworkRead(on)
//}
//
//func (self *Control) SyncEnabled(on bool) {
//	self.hive.SyncEnabled(on)
//}
//
//func (self *Control) SwapEnabled(on bool) {
//	self.hive.SwapEnabled(on)
//}
//
func (c *Control) Hive() string {
	return c.hive.String()
}
