pragma solidity >=0.4.0 <0.6.0;


/// @author The Papyrus team.
/// @title Helper contract providing queue implementation.
/// @dev No storage data here because the contract is inherited.
contract QueueHelper {
    uint8 constant queueLen = 5;

    struct Queue {
        uint8 top;
        uint8 bottom;
        Entry[queueLen] entries;
    }

    struct Entry {
        uint224 stake;
        uint32 timestamp;
    }

    function push(Queue storage queue, Entry memory entry) internal {
        require(queue.entries[queue.top].timestamp == 0);
        queue.entries[queue.top] = entry;
        advance(queue);
    }

    function pop(Queue storage queue) internal {
        require(size(queue) != 0);
        delete queue.entries[queue.bottom];
        queue.bottom = (queue.bottom + 1) % queueLen;
    }

    function head(Queue storage queue) view internal returns (Entry storage) {
        return queue.entries[queue.bottom];
    }

    function size(Queue storage queue) view internal returns (uint8) {
        if (queue.top == queue.bottom && queue.entries[queue.top].timestamp != 0) {
            return queueLen;
        }
        return uint8(int(queue.top) - int(queue.bottom)) % queueLen;
    }

    function advance(Queue storage queue) private {
        queue.top = (queue.top + 1) % queueLen;
    }
}
