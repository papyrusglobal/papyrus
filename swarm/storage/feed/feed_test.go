// Copyright 2018 The papyrus Authors
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
package feed

import (
	"testing"
)

func getTestFeed() *Feed {
	topic, _ := NewTopic("world news report, every hour", nil)
	return &Feed{
		Topic: topic,
		User:  newCharlieSigner().Address(),
	}
}

func TestFeedSerializerDeserializer(t *testing.T) {
	testBinarySerializerRecovery(t, getTestFeed(), "0x776f726c64206e657773207265706f72742c20657665727920686f7572000000876a8936a7cd0b79ef0735ad0896c1afe278781c")
}

func TestFeedSerializerLengthCheck(t *testing.T) {
	testBinarySerializerLengthCheck(t, getTestFeed())
}
