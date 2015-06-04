cimport counttrie.trienode as tn
from cpython cimport bool

cdef class CountTrie:
    '''
    Represents a trie (prefix tree), i.e., stores a set of strings in a tree fashion.
    The tree allows strings of various lengths to be stored, and keeps track
    of how many instances of each string has been added.
    '''

    cdef object root

    def __init__(self):
        '''
        Constructor. Creates an empty tree. A node for the empty string
        is always present.
        '''
        self.root = tn.TrieNode("", 0)


    cpdef add(self, str seq, int count=1):
        '''Adds a sequence to the tree.'''
        if seq == None or len(seq) == 0:
            self.root.cnt += count
        else:
            self.__add_recursively(self.root, seq, count)


    cdef __add_recursively(self, object node, str seq, int count):
        '''Recursively adds the sequence at the level beneath the specified node'''
        if seq == None or len(seq) == 0:
            raise RuntimeError("Cannot recursively add empty sequence")
        cdef str c = seq[0]
        cdef object n
        if c in node.children:
            n = node.children[c]
        else:
            n = tn.TrieNode(c, 0)
            node.children[c] = n
        if len(seq) == 1:
            n.cnt += count   # Leaf count
        else:
            self.__add_recursively(n, seq[1:], count)


    def __iadd__(self, str seq):
        '''Adds a sequence'''
        self.add(seq)


    def __contains__(self, str seq):
        '''Returns true if a tree contains a sequence.'''
        if seq is None or len(seq) == 0:
            return (self.root.cnt >= 1)
        return self.__contains_recursively(self.root, seq)


    cdef bool __contains_recursively(self, object node, str seq):
        '''Recursively searches for a sequence, returning true if in the tree.'''
        if seq == None or len(seq) == 0:
            raise RuntimeError("Cannot recursively find empty sequence")
        cdef str c = seq[0]
        cdef object n
        if c in node.children:
            n = node.children[c]
            if len(seq) == 1:
                return n.cnt >= 1
            else:
                return self.__contains_recursively(n, seq[1:])
        return False


    cpdef remove(self, str seq, bool allinstances=True):
        '''Removes a sequence from the tree, or just a count.'''
        if seq is None or len(seq) == 0:
            if allinstances:
                self.root.cnt = 0
            else:
                self.root.cnt = max(0, self.root.cnt - 1)
        elif seq in self:
            self.__remove_recursively(self.root, seq, allinstances)


    cdef __remove_recursively(self, object node, str seq, bool allinstances):
        '''Recursively removes a sequence from the tree.
        NB: It is assumed the sequence does exist!!!!'''
        if seq == None or len(seq) == 0:
            raise RuntimeError("Cannot recursively remove empty sequence")
        cdef str c = seq[0]
        cdef object n = node.children[c]
        if len(seq) == 1:
            if n.children is None:
                if allinstances:
                    del node.children[c]  # Leaf node
                else:
                    n.cnt = max(0, n.cnt - 1) # Leaf node
            else:
                if allinstances:
                    n.cnt = 0   # Internal node
                else:
                    n.cnt = max(0, n.cnt - 1)   # Internal node
        else:
            self.__remove_recursively(n, seq[1:], allinstances)

    def __isub__(self, str seq):
        '''Removes all instances of a sequence.'''
        self.remove(seq)


    cpdef list get_sequences(self):
        '''Returns all the unique sequences of the tree as a list,
        with counts as a second list.'''
        cdef list seqs = []
        cdef list cnts = []
        self.__get_sequences_recursively(self.root, "", seqs, cnts)
        return [seqs, cnts]


    cdef __get_sequences_recursively(self, object node, str seq, list seqs, list cnts):
        '''Returns all the unique sequences of the tree recursively.'''
        if node is None:
            return
        seq += node.chr
        if node.cnt >= 1:
            seqs.append(seq)
            cnts.append(node.cnt)
        cdef object n
        for n in node.children.values():
            self.__get_sequences_recursively(n, seq, seqs, cnts)


    cpdef int get_count(self, str seq):
        '''Returns the count of a sequence.'''
        if seq is None or len(seq) == 0:
            return self.root.cnt
        return self.__get_count_recursively(self.root, seq)


    cdef int __get_count_recursively(self, object node, str seq):
        '''Recursive helper to get_count()'''
        if seq == None or len(seq) == 0:
            raise RuntimeError("Cannot recursively find empty sequence")
        cdef str c = seq[0]
        cdef object n
        if c in node.children:
            n = node.children[c]
            if len(seq) == 1:
                return n.cnt
            else:
                return self.__get_count_recursively(n, seq[1:])
        return 0


    cpdef remove_count_range(self, int min, int max):
        '''Removes all sequences within count range [min,max].'''
        if self.root.cnt >= min and self.root.cnt <= max:
            self.root.cnt = 0
        cdef str c
        cdef bool childprune
        for c in self.root.children.keys():
            childprune = self.__remove_count_range(self.root.children[c], min, max)
            if childprune:
                del self.root.children[c]
        # Keep the root!


    cdef __remove_count_range(self, object node, int min, int max):
        '''Recursive helper to remove_count_range()'''
        cdef bool doprune
        cdef str c
        if node.cnt >= min and node.cnt <= max:
            node.cnt = 0
            doprune = True
        else:
            doprune = False
        for c in node.children.keys():
            childprune = self.__remove_count_range(node.children[c], min, max)
            doprune = (doprune and childprune)
            if childprune:
                del node.children[c]
        return doprune


    cpdef set find(self, str seq, int max_mismatches, bool allow_indels=False):
        '''Finds all sequences within a certain edit distance from
        a sequence, output as a set of sequences.'''
        cdef set found = set()
        if (seq is None or len(seq) == 0) and self.root.cnt >= 1:
            found.add(self.root.chr)
            return found
        cdef str c
        for c in self.root.children.keys():
            self.__find(self.root.children[c], seq, max_mismatches, allow_indels, "", 0, 0, found)
        return found


    cdef set __find(self, object node, str seq, int max_mismatches, bool allow_indels, str seqbuild, int pos, int mismatches, set found):
        '''Recursive helper to find()'''
        if seq[pos] != node.chr:
            # Mismatch
            mismatches += 1
            if mismatches > max_mismatches:
                return
        cdef str c
        if pos == len(seq)-1:
            if node.cnt >= 1: # Hit!
                found.add(seqbuild + node.chr)
            if allow_indels:
                for c in node.children.keys():
                    # Indel in seq.
                    self.__find(node.children[c], seq, max_mismatches, allow_indels, seqbuild+node.chr, pos, mismatches, found)
        else:
            for c in node.children.keys():
                # No indel.
                self.__find(node.children[c], seq, max_mismatches, allow_indels, seqbuild+node.chr, pos+1, mismatches, found)
                if allow_indels:
                    # Indel in seq.
                    self.__find(node.children[c], seq, max_mismatches, allow_indels, seqbuild+node.chr, pos, mismatches, found)
                    # Indel in seqbuild
                    self.__find(node, seq, max_mismatches, allow_indels, seqbuild, pos+1, mismatches, found)


    cpdef set find_equal_length_optimized(self, str seq, int max_mismatches, bool allow_indels=False):
        '''Finds all sequences within a certain edit distance from
        a sequence, output as a set of sequences ASSUMING the search string and all stored strings have equal length!'''
        cdef set found = set()
        if (seq is None or len(seq) == 0) and self.root.cnt >= 1:
            found.add(self.root.chr)
            return found
        cdef str c
        for c in self.root.children.keys():
            self.__find_equal_length_optimized(self.root.children[c], seq, max_mismatches, allow_indels, "", 0, 0, found)
        return found


    cdef set __find_equal_length_optimized(self, object node, str seq, int max_mismatches, bool allow_indels, str seqbuild, int pos, int mismatches, set found):
        '''Recursive helper to find_equal_length_optimized()'''
        cdef int tailmismatches
        if seq[pos] != node.chr:
            # Mismatch
            mismatches += 1
            if (mismatches + abs(pos - len(seqbuild))) > max_mismatches: # Min number indel mismatches to expect
                return
        cdef str c
        if pos == len(seq) - 1:
            if node.cnt >= 1: # Hit!
                found.add(seqbuild + node.chr)
        else:
            for c in node.children.keys():
                # No indel.
                self.__find(node.children[c], seq, max_mismatches, allow_indels, seqbuild+node.chr, pos+1, mismatches, found)
                if allow_indels:
                    # Indel in seq.
                    self.__find(node.children[c], seq, max_mismatches, allow_indels, seqbuild+node.chr, pos, mismatches, found)
                    # Indel in seqbuild
                    self.__find(node, seq, max_mismatches, allow_indels, seqbuild, pos+1, mismatches, found)


    cpdef int size(self, bool count_instances=False):
        '''Returns the size of the tree, either counting unique instances
        or counting all instances.'''
        cdef list sz = []
        sz.append(0)
        self.__size(self.root, sz, count_instances)
        return sz[0]


    cdef int __size(self, object node, list sz, bool count_instances):
        '''Recursive helper to size()'''
        if node.cnt >= 1:
            if count_instances:
                sz[0] += node.cnt
            else:
                sz[0] += 1
        cdef str c
        for c in node.children.keys():
            self.__size(node.children[c], sz, count_instances)


    def __len__(self):
        '''Implements len(trie).'''
        return self.size()
