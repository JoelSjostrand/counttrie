cdef class TrieNode:
    cdef public dict children
    cdef public str chr
    cdef public int cnt