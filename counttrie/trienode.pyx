cdef class TrieNode:
    '''Represents a character node in a prefix tree.
    May hold a value (although typically only leaf nodes).
    '''

    def __cinit__(self, str chr, int cnt):
        '''Constructor.'''
        self.children = dict()  # key: character, value: TrieNode.
        self.chr = chr         # character
        self.cnt = cnt          # Leaf count.