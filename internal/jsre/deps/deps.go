// Copyright 2017 The papyrus Authors
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

// Package deps contains the console JavaScript dependencies Go embedded.
package deps

//go:generate go-bindata -nometadata -pkg deps -o bindata.go bignumber.js web3.js
//go:generate gofmt -w -s bindata.go
