// Native Aho-Corasick — flat-array automaton for maximum search speed.
// Called from MoonBit via FFI on native target only.
// The automaton is dynamically allocated per build() call.

#include <moonbit.h>
#include <stdlib.h>
#include <string.h>

#define AC_ALPHABET 256
#define AC_MAX_OUTPUT 16

typedef struct {
    int (*goto_table);    // flat [num_states * AC_ALPHABET]
    int *fail;            // [num_states]
    int (*output)[AC_MAX_OUTPUT]; // [num_states][AC_MAX_OUTPUT]
    int *output_count;    // [num_states]
    int num_states;
    int num_patterns;
    int *pattern_lengths; // [num_patterns]
} NativeAC;

static NativeAC* g_ac = NULL;

static void free_ac(NativeAC* ac) {
    if (!ac) return;
    free(ac->goto_table);
    free(ac->fail);
    free(ac->output);
    free(ac->output_count);
    free(ac->pattern_lengths);
    free(ac);
}

// Build the automaton from pattern bytes.
// patterns: array of null-terminated C strings
// pattern_count: number of patterns
void native_ac_build(const uint8_t** patterns, const int32_t* pattern_lens,
                     int32_t pattern_count) {
    if (g_ac) free_ac(g_ac);

    int capacity = 256;
    NativeAC* ac = (NativeAC*)calloc(1, sizeof(NativeAC));
    ac->num_patterns = pattern_count;
    ac->num_states = 1;
    ac->goto_table = (int*)malloc(capacity * AC_ALPHABET * sizeof(int));
    ac->fail = (int*)calloc(capacity, sizeof(int));
    ac->output = (int(*)[AC_MAX_OUTPUT])calloc(capacity, sizeof(int[AC_MAX_OUTPUT]));
    ac->output_count = (int*)calloc(capacity, sizeof(int));
    ac->pattern_lengths = (int*)malloc(pattern_count * sizeof(int));

    memset(ac->goto_table, -1, capacity * AC_ALPHABET * sizeof(int));

    for (int p = 0; p < pattern_count; p++) {
        ac->pattern_lengths[p] = pattern_lens[p];
        int state = 0;
        for (int i = 0; i < pattern_lens[p]; i++) {
            int c = (unsigned char)patterns[p][i];
            int next = ac->goto_table[state * AC_ALPHABET + c];
            if (next == -1) {
                int ns = ac->num_states++;
                if (ns >= capacity) {
                    capacity *= 2;
                    ac->goto_table = (int*)realloc(ac->goto_table, capacity * AC_ALPHABET * sizeof(int));
                    memset(ac->goto_table + (capacity/2) * AC_ALPHABET, -1,
                           (capacity/2) * AC_ALPHABET * sizeof(int));
                    ac->fail = (int*)realloc(ac->fail, capacity * sizeof(int));
                    memset(ac->fail + capacity/2, 0, (capacity/2) * sizeof(int));
                    ac->output = (int(*)[AC_MAX_OUTPUT])realloc(ac->output, capacity * sizeof(int[AC_MAX_OUTPUT]));
                    memset(ac->output + capacity/2, 0, (capacity/2) * sizeof(int[AC_MAX_OUTPUT]));
                    ac->output_count = (int*)realloc(ac->output_count, capacity * sizeof(int));
                    memset(ac->output_count + capacity/2, 0, (capacity/2) * sizeof(int));
                }
                ac->goto_table[state * AC_ALPHABET + c] = ns;
                next = ns;
            }
            state = next;
        }
        if (ac->output_count[state] < AC_MAX_OUTPUT)
            ac->output[state][ac->output_count[state]++] = p;
    }

    // Root: unmatched chars go to root
    for (int c = 0; c < AC_ALPHABET; c++)
        if (ac->goto_table[c] == -1) ac->goto_table[c] = 0;

    // BFS for failure links
    int* queue = (int*)malloc(ac->num_states * sizeof(int));
    int qh = 0, qt = 0;

    for (int c = 0; c < AC_ALPHABET; c++) {
        int s = ac->goto_table[c];
        if (s != 0) { ac->fail[s] = 0; queue[qt++] = s; }
    }

    while (qh < qt) {
        int r = queue[qh++];
        for (int c = 0; c < AC_ALPHABET; c++) {
            int s = ac->goto_table[r * AC_ALPHABET + c];
            if (s == -1) {
                ac->goto_table[r * AC_ALPHABET + c] = ac->goto_table[ac->fail[r] * AC_ALPHABET + c];
            } else {
                ac->fail[s] = ac->goto_table[ac->fail[r] * AC_ALPHABET + c];
                // Merge output
                for (int k = 0; k < ac->output_count[ac->fail[s]]; k++) {
                    if (ac->output_count[s] < AC_MAX_OUTPUT)
                        ac->output[s][ac->output_count[s]++] = ac->output[ac->fail[s]][k];
                }
                queue[qt++] = s;
            }
        }
    }

    free(queue);
    g_ac = ac;
}

// Search text, return number of unique patterns matched.
// results[i] = 1 if pattern i matched, 0 otherwise.
// Lowercases ASCII during scan (a-Z → a-z).
int32_t native_ac_search(const uint8_t* text, int32_t text_len,
                         int32_t* results, int32_t pattern_count) {
    if (!g_ac) return 0;
    for (int i = 0; i < pattern_count; i++) results[i] = 0;
    int found = 0;
    int state = 0;

    for (int i = 0; i < text_len; i++) {
        int c = text[i];
        if (c >= 'A' && c <= 'Z') c += 32;
        state = g_ac->goto_table[state * AC_ALPHABET + c];
        for (int k = 0; k < g_ac->output_count[state]; k++) {
            int p = g_ac->output[state][k];
            if (p < pattern_count && !results[p]) {
                results[p] = 1;
                found++;
            }
        }
    }
    return found;
}

// Search and return match positions. Writes to positions array:
// [pattern_index, start, end, pattern_index, start, end, ...]
// Returns number of matches written (each match = 3 ints).
int32_t native_ac_search_positions(const uint8_t* text, int32_t text_len,
                                   int32_t* positions, int32_t max_matches) {
    if (!g_ac) return 0;
    int count = 0;
    int state = 0;

    for (int i = 0; i < text_len; i++) {
        int c = text[i];
        state = g_ac->goto_table[state * AC_ALPHABET + c];
        for (int k = 0; k < g_ac->output_count[state]; k++) {
            int p = g_ac->output[state][k];
            if (count < max_matches) {
                int pos = i + 1;
                positions[count * 3] = p;
                positions[count * 3 + 1] = pos - g_ac->pattern_lengths[p];
                positions[count * 3 + 2] = pos;
                count++;
            }
        }
    }
    return count;
}

// Check if any pattern matches. Short-circuits.
int32_t native_ac_contains_any(const uint8_t* text, int32_t text_len) {
    if (!g_ac) return 0;
    int state = 0;

    for (int i = 0; i < text_len; i++) {
        int c = text[i];
        if (c >= 'A' && c <= 'Z') c += 32;
        state = g_ac->goto_table[state * AC_ALPHABET + c];
        if (g_ac->output_count[state] > 0) return 1;
    }
    return 0;
}

// Count total matches (with duplicates at different positions).
int32_t native_ac_count(const uint8_t* text, int32_t text_len) {
    if (!g_ac) return 0;
    int total = 0;
    int state = 0;

    for (int i = 0; i < text_len; i++) {
        int c = text[i];
        state = g_ac->goto_table[state * AC_ALPHABET + c];
        total += g_ac->output_count[state];
    }
    return total;
}

// Return number of states (for diagnostics).
int32_t native_ac_state_count(void) {
    return g_ac ? g_ac->num_states : 0;
}
