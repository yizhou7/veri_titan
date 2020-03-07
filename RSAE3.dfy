include "NativeTypes.dfy"
include "Powers.dfy"
include "Congruences.dfy"

module RSAE3 {
    import opened NativeTypes
    import opened Powers
    import opened Congruences

    const BASE :int := UINT32_MAX as int + 1;

    function method reinterpret_cast(a: int64) : uint64

    // |A[..i]| == i, interp A[..i] as an int 
    function interp(A: seq<uint32>, i: int) : int
        decreases i;
        requires 0 <= i <= |A|;
    {
        if i == 0 then 0
        else word_interp(A, i - 1) + interp(A, i - 1)
    }

    function R(n: nat) : int
        ensures R(n) != 0;
    {
        reveal power();
        power(BASE, n)
    }

    function word_interp(A: seq<uint32>, i: nat) : int
        requires i < |A|;
    {
        A[i] as int * postional_weight(i)
    }

    function postional_weight(i: nat) : nat
    {
        power(BASE, i) as nat
    }

    lemma word_interp_upper_bound_lemma(A: seq<uint32>, i: nat)
        requires i < |A|;
        ensures word_interp(A, i) <= power(BASE, i + 1) - power(BASE, i);
    {
        assert A[i] as int <= BASE;
        calc ==> {
            A[i] as int <= BASE;
            A[i] as int * postional_weight(i) <= (BASE - 1) * postional_weight(i);
            {
                assert word_interp(A, i) == A[i] as int * postional_weight(i);
            }
             word_interp(A, i) <= (BASE - 1) * postional_weight(i);
             word_interp(A, i) <= (BASE - 1) * power(BASE, i);
             word_interp(A, i) <= BASE * power(BASE, i) - power(BASE, i);
             {
                power_add_one_lema(BASE, i);
             }
             word_interp(A, i) <= power(BASE, i + 1) - power(BASE, i);
        }
    }

    function seq_interp(A: seq<uint32>) : int
    {
        interp(A, |A|)
    }

    lemma {:induction A} seq_interp_max_bound_lemma(A: seq<uint32>)
        requires |A| != 0;
        ensures seq_interp(A) < R(|A|);
    {
        if |A| == 1 {
            reveal power();
        } else {
            ghost var A' := A[..(|A| - 1)];

            calc ==> {
                seq_interp(A) == word_interp(A, |A| - 1) + interp(A, |A| - 1);
                {
                    assume seq_interp(A') == interp(A, |A| - 1);
                }
                seq_interp(A) == word_interp(A, |A| - 1) + seq_interp(A');
                {
                    assert seq_interp(A') < power(BASE, |A'|);
                }
                seq_interp(A) < word_interp(A, |A| - 1) + power(BASE, |A'|);
                {
                    assert word_interp(A, |A| - 1) <= power(BASE, |A|) - power(BASE, |A| - 1) by {
                        word_interp_upper_bound_lemma(A, |A| - 1);
                    }
                }
                seq_interp(A) < power(BASE, |A|) - power(BASE, |A| - 1) + power(BASE, |A'|);
                seq_interp(A) < power(BASE, |A|);
            }
        }
    }

    lemma postional_shift_lemma(i: int)
        requires i > 0;
        ensures postional_weight(i - 1) * BASE == postional_weight(i);
    {
        calc == {
            postional_weight(i - 1) * BASE;
            ==
            power(BASE, i - 1) * BASE;
            {
                power_add_one_lema(BASE, i - 1);
            }
            power(BASE, i);
            ==
            postional_weight(i);
        }
    }

    lemma {:induction i} prefix_sum_lemma(S: seq<uint32>, S': seq<uint32>, i: nat)
        requires 0 <= i <= |S| && 0 <= i <= |S'|;
        requires S[..i] == S'[..i];
        ensures interp(S, i) == interp(S', i);
    {
        assert true;
    }

    method seq_add_c(A: seq<uint32>, B: seq<uint32>, n: nat) returns (c: uint2, S:seq<uint32>)
        requires |A| == |B| == n;
        ensures |S| == n;
        ensures seq_interp(A) + seq_interp(B) == seq_interp(S) + c as int * postional_weight(n);
    {
        var temp := new uint32[|A|];
        c, S := 0, temp[..];

        var i: nat := 0;

        while i < n
            invariant |S| == |A|;
            invariant 0 <= i <= |A|;
            decreases |A| - i;
            invariant interp(A, i) + interp(B, i) == interp(S, i) + c as int * postional_weight(i);
        {
            ghost var c_old, i_old: int := c, i;
            assert interp(A, i_old) + interp(B, i_old) == interp(S, i_old) + c_old as int * postional_weight(i_old);

            var sum: uint64 := A[i] as uint64 + B[i] as uint64 + c as uint64;
            var masked := and64(sum, UINT32_MAX as uint64) as uint32;
            assume masked as int + BASE == sum as int;

            ghost var S_old := S;
            ghost var prefix_sum := interp(S_old, i);
            S := S[i := masked];

            assert prefix_sum == interp(S, i_old) by {
                prefix_sum_lemma(S, S_old, i_old);
                assert interp(S, i_old) == interp(S_old, i_old);
            }

            i := i + 1;

            assert interp(A, i_old) + interp(B, i_old) == interp(S, i_old) + c_old as int * postional_weight(i_old);
            assert interp(S, i) == masked as int * postional_weight(i_old) + interp(S, i_old);
            assert interp(B, i) == B[i - 1] as int * postional_weight(i - 1) + interp(B, i - 1);
            assert interp(A, i) == A[i - 1] as int * postional_weight(i - 1) + interp(A, i - 1);

            calc == {
                interp(A, i) + interp(B, i);
                ==
                A[i - 1] as int * postional_weight(i - 1) + interp(A, i_old) +
                B[i - 1] as int * postional_weight(i - 1) + interp(B, i_old);
                ==
                A[i - 1] as int * postional_weight(i - 1) + 
                B[i - 1] as int * postional_weight(i - 1) +
                interp(S, i_old) + c_old as int * postional_weight(i_old);
                ==
                postional_weight(i - 1) * (A[i - 1] as int + B[i - 1] as int + c_old as int) +
                interp(S, i_old);
                ==
                postional_weight(i - 1) * (sum as int) + interp(S, i_old);
            }

            if sum > UINT32_MAX as uint64 {
                c := 1;
                calc == {
                    postional_weight(i - 1) * (sum as int) + interp(S, i_old);
                    postional_weight(i - 1) * masked as int + postional_weight(i - 1) * BASE + interp(S, i_old);
                    {
                        postional_shift_lemma(i);
                    }
                    postional_weight(i - 1) * masked as int + postional_weight(i) + interp(S, i_old);
                }
            } else {
                c := 0;
            }
            assert interp(A, i) + interp(B, i) == interp(S, i) + c as int * postional_weight(i);
        }
    }

    lemma seq_add_0_index_lemma(A: seq<uint32>, B: seq<uint32>, S: seq<uint32>, n: nat) 
        requires n != 0
        requires |A| == |B| == |S| == n;
        requires cong(seq_interp(A) + seq_interp(B), seq_interp(S), power(BASE, n));
        ensures cong(S[0] as int, A[0] as int + B[0] as int, BASE);
    {
        assume false;
    }

    method seq_add(A: seq<uint32>, B: seq<uint32>, n: nat) returns (S: seq<uint32>)
        requires |A| == |B| == n;
        ensures |S| == n;
        ensures cong(seq_interp(A) + seq_interp(B), seq_interp(S), power(BASE, n));
        ensures n != 0 ==> cong(S[0] as int, A[0] as int + B[0] as int, BASE);
    {
        var c;
        c, S := seq_add_c(A, B, n);

        if c == 0 {
            assert cong(seq_interp(A) + seq_interp(B), seq_interp(S), power(BASE, n)) by {
                assert seq_interp(A) + seq_interp(B) == seq_interp(S);
                reveal cong();
            }
        } else {
            assert cong(seq_interp(A) + seq_interp(B), seq_interp(S), power(BASE, n)) by {
                assert cong(seq_interp(A) + seq_interp(B), seq_interp(S) + postional_weight(n), power(BASE, n)) by {
                    assert seq_interp(A) + seq_interp(B) == seq_interp(S) + postional_weight(n);
                    reveal cong();
                }
                assert cong(seq_interp(S) + power(BASE, n), seq_interp(S), power(BASE, n)) by {
                    cong_add_lemma_3(seq_interp(S), power(BASE, n));
                    reveal cong();
                }
                cong_trans_lemma(seq_interp(A) + seq_interp(B), seq_interp(S) + power(BASE, n), seq_interp(S), power(BASE, n));
            }
        }
        assume false;
    }

    method seq_zero_extend(A: seq<uint32>, n: nat, m: nat) returns (A': seq<uint32>)
        requires |A| == n;
        requires m > n;
        ensures |A'| == m;
        ensures seq_interp(A') == seq_interp(A); 
    {
        assume false;
    }

    method seq_sub(A: seq<uint32>, B: seq<uint32>) returns (b: uint2, S:seq<uint32>)
        requires |A| == |B|;
        ensures seq_interp(A) - seq_interp(B) == seq_interp(S) - b as int * postional_weight(|A|);
    {
        var temp := new uint32[|A|];
        b, S := 0, temp[..];

        var i: nat := 0;

        while i < |A|
            invariant |S| == |A|;
            invariant 0 <= i <= |A|;
            decreases |A| - i;
            invariant interp(A, i) - interp(B, i) == interp(S, i) - b as int * postional_weight(i);
        {
            var b_old, i_old: int := b, i;
            assert interp(A, i_old) - interp(B, i_old) == interp(S, i_old) - b_old as int * postional_weight(i_old);

            var diff: int64 := A[i] as int64 - B[i] as int64 - b as int64;
            var masked := and64(reinterpret_cast(diff), UINT32_MAX as uint64) as uint32;

            assume diff < 0 ==> masked as int == diff as int + BASE as int;
            assume diff >= 0 ==> masked as int == diff as int;

            ghost var S_old := S;
            ghost var prefix_sum := interp(S_old, i);
            S := S[i := masked];

            assert prefix_sum == interp(S, i_old) by {
                prefix_sum_lemma(S, S_old, i_old);
                assert interp(S, i_old) == interp(S_old, i_old);
            }

            i := i + 1;

            assert interp(A, i_old) - interp(B, i_old) == interp(S, i_old) - b_old as int * postional_weight(i_old);
            assert interp(S, i) == masked as int * postional_weight(i_old) + interp(S, i_old);
            assert interp(B, i) == B[i - 1] as int * postional_weight(i - 1) + interp(B, i - 1);
            assert interp(A, i) == A[i - 1] as int * postional_weight(i - 1) + interp(A, i - 1);

            calc == {
                interp(A, i) - interp(B, i);
                ==
                A[i - 1] as int * postional_weight(i - 1) + interp(A, i_old) -
                B[i - 1] as int * postional_weight(i - 1) - interp(B, i_old);
                ==
                A[i - 1] as int * postional_weight(i - 1) - 
                B[i - 1] as int * postional_weight(i - 1) +
                interp(S, i_old) - b_old as int * postional_weight(i_old);
                ==
                postional_weight(i - 1) * (A[i - 1] as int - B[i - 1] as int - b_old as int) +
                interp(S, i_old);
            }

            if diff < 0 {
                b := 1;
                calc == {
                    postional_weight(i - 1) * (diff as int) + interp(S, i_old);
                    postional_weight(i - 1) * masked as int - postional_weight(i - 1) * BASE + interp(S, i_old);
                    {
                        postional_shift_lemma(i);
                    }
                    postional_weight(i - 1) * masked as int - postional_weight(i) + interp(S, i_old);
                }
            } else {                
                b := 0;
                assert interp(A, i) - interp(B, i) == interp(S, i);
            }
            assert interp(A, i) - interp(B, i) == interp(S, i) - b as int * postional_weight(i);
        }
    }

    lemma mont_mul_div_aux_lemma_2(y: int, x: int, m: int, a: int, m': int)
        requires cong(m' * m, -1, BASE);
        ensures cong(m * (((a + x * y) * m') % BASE), -(a + x * y), BASE);
    {
        assert A_1: cong(((a + x * y) * m') % BASE, (a + x * y) * m', BASE) by {
            mod_mod_lemma((a + x * y) * m', BASE);
        }

        ghost var temp_1 := m * (((a + x * y) * m') % BASE);
        ghost var temp_2 := -(a + x * y);
   
        calc ==> {
            cong(((a + x * y) * m') % BASE, (a + x * y) * m', BASE);
            {
                cong_mul_lemma(((a + x * y) * m') % BASE, (a + x * y) * m', m, BASE);
            }
            cong(temp_1, m * (a + x * y) * m', BASE);
            {
                assert m * (a + x * y) * m' == m * m' * (a + x * y);
            }
            cong(temp_1, m * m' * (a + x * y), BASE);
            {
                assert cong(m * m' * (a + x * y), -(a + x * y), BASE) by {
                    assert cong(m' * m, -1, BASE);
                    cong_mul_lemma(m' * m, -1, (a + x * y), BASE);
                }
                cong_trans_lemma(temp_1, m * m' * (a + x * y), -(a + x * y), BASE);
            }
            cong(temp_1, -(a + x * y), BASE);
            cong(temp_1, temp_2, BASE);
        }

        assert cong(temp_1, temp_2, BASE) by {
            reveal A_1;
        }

        calc ==> {
            cong(temp_1, temp_2, BASE);
            cong(m * (((a + x * y) * m') % BASE), temp_2, BASE);
            cong(m * (((a + x * y) * m') % BASE), -(a + x * y), BASE);
        }

        assert cong(m * (((a + x * y) * m') % BASE), -(a + x * y), BASE);
    }

    lemma mont_mul_div_aux_lemma_1(y: int, x: int, m: int, a: int, m': int)
        requires cong(m' * m, -1, BASE);
        ensures cong(y * x + m * (((a + x * y) * m') % BASE) + a, 0, BASE);
    {
        ghost var temp_1 := m * (((a + x * y) * m') % BASE);
        ghost var temp_2 := -(a + x * y);
        ghost var temp_3 := x * y;

        assert cong(temp_1, temp_2, BASE) by {
            mont_mul_div_aux_lemma_2(y, x, m, a, m');
        }

        calc ==> {
            cong(temp_1, temp_2, BASE);
            {
                cong_add_lemma_1(temp_1, temp_2, temp_3, BASE);
            }
            cong(temp_1 + temp_3, temp_2 + temp_3, BASE);
            cong(temp_1 + temp_3, -(a + x * y) + x * y, BASE);
            cong(temp_1 + temp_3, -a - x * y + x * y, BASE);
            cong(temp_1 + temp_3, -a, BASE);
            {
                cong_add_lemma_1(temp_1 + temp_3, -a, a, BASE);
            }
            cong(temp_1 + temp_3 + a, 0, BASE);
            cong(temp_3 + temp_1 + a, 0, BASE);
            cong(x * y + temp_1 + a, 0, BASE);
            cong(x * y + m * (((a + x * y) * m') % BASE) + a, 0, BASE);
        }
        assert cong(x * y + m * (((a + x * y) * m') % BASE) + a, 0, BASE);
    }

    lemma mont_mul_divisible_lemma(m: seq<uint32>,
        x: seq<uint32>,
        y: seq<uint32>,
        P_1: seq<uint32>,
        P_2: seq<uint32>,
        S: seq<uint32>,
        A: seq<uint32>,
        A': seq<uint32>,
        i: nat,
        u_i: uint32,
        m': uint32,
        n: nat)

        requires n > 2 && i < n;
        requires |m| == |x| == |y| == n;
        requires |P_1| ==|P_2| == n + 1;
        requires |A'| == |S| == |A| == n + 1;
        requires cong(m' as int * m[0] as int, -1, BASE);

        requires u_i as int == ((A[0] as int + x[i] as int * y[0] as int) * m' as int) % BASE;

        requires cong(P_1[0] as int, y[0] as int * x[i] as int, BASE);
        requires cong(P_2[0] as int, m[0] as int * u_i as int, BASE);

        requires cong(seq_interp(A) + seq_interp(S), seq_interp(A'), power(BASE, n + 1));
        requires cong(S[0] as int, P_1[0] as int + P_2[0] as int, BASE);
        ensures cong(A'[0] as int, 0, BASE);
    {
        calc ==> {
            cong(S[0] as int, P_1[0] as int + P_2[0] as int, BASE);
            {
                cong_add_lemma_1(S[0] as int, P_1[0] as int + P_2[0] as int, A[0] as int,BASE);
            }
            cong(S[0] as int + A[0] as int, P_1[0] as int + P_2[0] as int + A[0] as int, BASE);
            {
                assert cong(A'[0] as int, A[0] as int + S[0] as int, BASE) by {
                    seq_add_0_index_lemma(A, S, A', n + 1); 
                }
                cong_trans_lemma(A'[0] as int, A[0] as int + S[0] as int,
                    P_1[0] as int + P_2[0] as int + A[0] as int,
                    BASE);
            }
            cong(A'[0] as int, P_1[0] as int + P_2[0] as int + A[0] as int, BASE);
            {
                assert cong(P_1[0] as int + P_2[0] as int + A[0] as int, y[0] as int * x[i] as int + m[0] as int * u_i as int + A[0] as int, BASE) by {
                    assert cong(P_1[0] as int + P_2[0] as int, y[0] as int * x[i] as int + m[0] as int * u_i as int, BASE) by {
                        assert cong(P_1[0] as int, y[0] as int * x[i] as int, BASE);
                        assert cong(P_2[0] as int, m[0] as int * u_i as int, BASE);
                        cong_add_lemma_2(P_1[0] as int, y[0] as int * x[i] as int, P_2[0] as int, m[0] as int * u_i as int, BASE);
                    }
                    cong_add_lemma_1(P_1[0] as int + P_2[0] as int, y[0] as int * x[i] as int + m[0] as int * u_i as int, A[0] as int, BASE);
                }
                cong_trans_lemma(A'[0] as int, P_1[0] as int + P_2[0] as int + A[0] as int, y[0] as int * x[i] as int + m[0] as int * u_i as int + A[0] as int, BASE);
            }
            cong(A'[0] as int, y[0] as int * x[i] as int + m[0] as int * u_i as int + A[0] as int, BASE);
            {
                assert u_i as int == ((A[0] as int + x[i] as int * y[0] as int) * m' as int) % BASE;
            }
            cong(A'[0] as int, y[0] as int * x[i] as int + m[0] as int * (((A[0] as int + x[i] as int * y[0] as int) * m' as int) % BASE) + A[0] as int, BASE);
            {
                assert cong(y[0] as int * x[i] as int + m[0] as int * (((A[0] as int + x[i] as int * y[0] as int) * m' as int) % BASE) + A[0] as int, 0, BASE) by {
                    mont_mul_div_aux_lemma_1(y[0] as int, x[i] as int, m[0] as int, A[0] as int , m' as int);
                }
                cong_trans_lemma(A'[0] as int, y[0] as int * x[i] as int + m[0] as int * (((A[0] as int + x[i] as int * y[0] as int) * m' as int) % BASE) + A[0] as int, 0, BASE);
            }
            cong(A'[0] as int, 0, BASE);
        }
        assert cong(A'[0] as int, 0, BASE);
    }

    lemma lsw_inverse_lemma(m: seq<uint32>, m': uint32)
        requires |m| != 0;
        requires cong(m' as int * seq_interp(m), -1, BASE);
        ensures cong(m' as int * m[0] as int, -1, BASE);
    {
        assume false;
    }

    method mont_mul(m: seq<uint32>, x: seq<uint32>, y: seq<uint32>, m': uint32, n: nat, ghost R: int)
        requires n > 2;
        requires |m| == n && |x| == n && |y| == n;
        requires R == power(BASE, n);
        requires cong(m' as int * seq_interp(m), -1, BASE);
    {
        var temp := new uint32[n + 1];
        var A :seq<uint32> := temp[..];
        var i := 0;

        while i < n
            decreases n - i;
        {
            var u_i_ := ((A[0] as int + x[i] as int * y[0] as int) * m' as int) % BASE; 
            var u_i := u_i_ as uint32;

            var P_1 := magic_mul(y, x[i], n);
            var P_2 := magic_mul(m, u_i, n);
            var S := seq_add(P_1, P_2, n + 1);
            var A' := seq_add(A, S, n + 1);

            assert cong(m' as int * m[0] as int, -1, BASE) by {
                lsw_inverse_lemma(m, m');
            }

            assert cong(A'[0] as int, 0, BASE) by {
                mont_mul_divisible_lemma(m, x, y, P_1, P_2, S, A, A', i, u_i, m', n);
            }
   
            i := i + 1;
        }
    }

    method magic_mul(A: seq<uint32>, b: uint32, n: nat)
        returns (P: seq<uint32>)
        requires n != 0;
        requires |A| == n;
        ensures |P| == n + 1;
        ensures seq_interp(P) == seq_interp(A) * b as int;
        ensures cong(P[0] as int, A[0] as int * b as int, BASE);
    {
        assume false;
    }

    // method mont_red(T: seq<uint32>, M: seq<uint32>, n: nat, m': uint32, R: nat)
    //     returns (A': seq<uint32>)
    //     requires |M| == n as int;
    //     requires |T| == 2 * n as int;
    //     requires R == power(BASE, n as nat);
    // {
    //     var A := T;

    //     var i := 0;
    //     while i < n
    //         invariant 0 <= i <= n;
    //         invariant |A| == 2 * n as int;
    //         decreases |A| - i;
    //         invariant forall j :: 0 <= j < i ==> A[j] == 0;
    //     {
    //         A := mont_red_step(A, M, n, i, m', R);
    //         i := i + 1;
    //     }
    // }

    // method mont_red_step(A: seq<uint32>, M: seq<uint32>, n: nat, i: nat, m': uint32, R: nat)
    //     returns (A': seq<uint32>)

    //     requires |A| == 2 * n as int;
    //     requires |M| == n as int;

    //     requires 0 <= i < n;
    //     requires forall j :: 0 <= j < i ==> A[j] == 0;

    //     ensures |A| == |A'|;
    //     ensures forall j :: 0 <= j <= i ==> A'[j] == 0;
    // {
    //     var p_i := A[i] as nat * m' as nat; // there should be a better way
    //     var u_i :uint32 := (p_i % BASE) as uint32;

    //     A' := seq_add_pos(A, M, n, i, u_i, m');
    // }

    // method seq_add_pos(A: seq<uint32>, M: seq<uint32>, n: nat, i: nat, u_i: uint32, m': uint32) 
    //     returns (A': seq<uint32>)
    //     requires |A| == 2 * n as int;
    //     requires 0 <= i < n;
    //     requires forall j :: 0 <= j < i ==> A[j] == 0;

    //     ensures |A| == |A'|;
    //     ensures cong(seq_interp(A), seq_interp(A') + (u_i as int) * seq_interp(M) * power(BASE, i), MOD(A));
    //     ensures forall j :: 0 <= j <= i ==> A'[j] == 0;
    // {
    //     A' := A;
    //     var i := i;
    //     var P := magic_mul(M, n, i, u_i);
        
    //     assume false;
    // }

    // method modpow3(A: nat, N:nat, R: nat, RR: nat)
    //     requires RR == R * R;
    // {
    //     montMul(key, aR, a, RR);       /* aR = M * RR / R mod N   */
    //     montMul(key, aaR, aR, aR);     /* aaR = aR * MR / R mod N */
    //     montMul(key, aaa, aaR, a);     /* aaa = aaR * a / R mod N */
        
    //     if (geM(key, aaa)) {
    //        subM(key, aaa);
    //     }
    // }
}