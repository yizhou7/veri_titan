module MONTGOMERY {
    predicate congruent_def(a: int, b: int, n: int)
    {
        exists k : int :: a - b == n * k
    }

    lemma congruent_add_lema(a: int, b: int, c: int, d: int, n: nat)
        requires n != 0;
        requires congruent_def(a, b, n) && congruent_def(c, d, n)
        ensures congruent_def(a + c, b + d, n)
    {
        var k_1, k_2 : int :| a - b == n * k_1 && c - d == n * k_2;
        calc == {
            (a + c) - (b + d);
            ==
            (a - b) + (c - d);
            ==
            n * k_1 + n * k_2;
            ==
            (k_1 + k_2) * n;
        }

        ghost var k := (k_1 + k_2);
        assert (a + c) - (b + d) == n * k;
    }

    lemma congruent_sub_lema(a: int, b: int, c: int, d: int, n: nat)
        requires n != 0;
        requires congruent_def(a, b, n) && congruent_def(c, d, n)
        ensures congruent_def(a - c, b - d, n)
    {
        var k_1, k_2 : int :| a - b == n * k_1 && c - d == n * k_2;
        calc == {
            (a - c) - (b - d);
            ==
            n * k_1 - n * k_2;
            ==
            (k_1 - k_2) * n;
        }

        ghost var k := (k_1 +- k_2);
        assert (a - c) - (b - d) == n * k;
    }

    predicate divides_def(d:nat, n:int)
        requires d != 0;
    {
        (n % d) == 0
    }

    predicate gcd_def(a:nat, b:nat, gcd:nat)
    {
        gcd != 0
        && divides_def(gcd,a)
        && divides_def(gcd,b)
        && forall x:int :: gcd < x ==> !(divides_def(x,a) && divides_def(x,b))
    }

    predicate mod_inverse_def(a:nat, x:nat, n:nat)
        requires n != 0;
    {
        (x * a) % n == 1
    }

    function method mod_inverse(a:nat, n:nat) : (x: nat)
        requires n > 0;
        ensures mod_inverse_def(a, x, n);
        ensures x < n;
    {
        assume false;
        42
    }

    predicate montgomery_reduction_def(N: nat, R: nat, T: nat, m: nat)
        requires gcd_def(N, R, 1);
        requires 0 <= T < N * R;
    {
        var R_inv := mod_inverse(R, N);
        m == (T * R_inv) % N
    }

    method montgomery_reduction(N: nat, R: nat, T: nat) returns (x: nat)
        requires gcd_def(N, R, 1);
        requires 0 <= T < (N * R);
        // ensures montgomery_reduction_def(N, R, T, x);
    {
        var N_inv := mod_inverse(N, R);
        var m := T * (R - N_inv);
        calc == {
            (T + m * N) % R;
            ==
            (T + T * (R - N_inv) * N) % R;
            ==
            {
                assert T * (1 + (R - N_inv) * N) == T + T * (R - N_inv) * N;
            }
            (T * (1 + (R - N_inv) * N )) % R;
            ==
            {
                calc == {
                    (1 + (R - N_inv) * N ) % R;
                    ==
                    {
                        assert (R - N_inv) * N == R * N - N_inv * N;
                    }
                    (1 + R * N - N_inv * N) % R;
                    // ==
                    // (1 - N_inv * N) % R;
                }
            }
            // (T * (1 + (R  * N - N_inv * N))) % R; 
        }

        assume (T + m * N) % R == 0;
        var t := (T + m * N) / R;
        assert t * R - T == m * N;
        // assert congruent_def(t * R, T, N);
        x := if N <= t then (t - N)
        else t;
        // assert congruent_def(t * R, T, N);
    }

    // method montgomery_mod(a: nat, b: nat, N:nat, R: nat) returns (x: nat)
    //     requires 0 < N < R &&  gcd_def(N, R, 1);
    // {
    //     var a' := (a * R) % N;
    //     var b' := (b * R) % N;
    //     var c' := montgomery_reduction(N, R, a' * b');
    //     x := montgomery_reduction(N, R, c');
    // }

// function method power(b:int, e:nat) : int
//     decreases e;
// {
//     if (e == 0) then 1
//     else b * power(b ,e - 1)
// }

// lemma {:induction e} exp_one_rule_lema(e: nat)
//     ensures power(1, e) == 1;
// {
//     assert true;
// }

// lemma {:induction e, e_1} exp_product_lema(b:int, e:nat, e_1:nat, e_2:nat)
// 	requires e_1 + e_2 == e; 
// 	ensures power(b, e) == power(b, e_1) * power(b, e_2)
// {
// 	if e_1 == 0 {
// 		assert true;
// 	} else {
// 		assert power(b, e_1) == b * power(b, e_1 - 1);
// 		assert power(b, e - 1) ==  power(b, e_1 - 1) * power(b, e_2);
// 	}
// }

// lemma {:induction e, e_2} exp_power_lema_1(b:int, e: nat, e_1:nat, e_2:nat)
//     decreases e, e_2;
//     requires e == e_1 * e_2
//     ensures power(b, e) == power(power(b, e_1), e_2)
// {
//     if e_2 == 0 {
//         assert true;
//     } else {
//         if e_1 == 0 {
//             assert e == 0;
//             calc == {
//                 power(power(b, e_1), e_2);
//                 ==
//                 power(power(b, 0), e_2);
//                 ==
//                 power(1, e_2);
//                 ==
//                 {
//                     exp_one_rule_lema(e_2);
//                 }
//                 1;
//             }
//         } else {
//             calc == {
//                 power(b, e);
//                 ==
//                 power(b, e_1 * e_2);
//                 ==
//                 {
//                     exp_product_lema(b, e_1 * e_2, e_1 * (e_2 - 1), e_1);
//                 }
//                 power(b, e_1 * (e_2 - 1)) *  power(b, e_1);
//                 ==
//                 {
//                     exp_power_lema_1(b, e_1 * (e_2 - 1), e_1, e_2 -1);
//                 }
//                 power(power(b, e_1), e_2 - 1) *  power(b, e_1);
//                 ==
//                 {
//                     exp_product_lema(power(b, e_1), e_2, e_2 - 1, 1);
//                 }
//                 power(power(b, e_1), e_2);
//             }
//         }
//     }
// }

// predicate congruent_def(a: int, b: int, n: int)
// {
//     exists k : int :: a - b == n * k
// }


// lemma mul_distrubtive_lema(n: int, a: int, b: int, c: int)
//     ensures n * (a + b + c) == n * a + n * b  + n * c;
// {
//     assert true;
// }

// lemma mod_mul_lema(a_1: int, a_2: int, b_1: int, b_2: int, n: int)
//     requires congruent_def(a_1, b_1, n) && congruent_def(a_2, b_2, n);
//     ensures congruent_def(a_1 * a_2, b_1 * b_2, n);
// {
//     ghost var k_1, k_2 : int :| a_1 - b_1 == n * k_1 && a_2 - b_2 == n * k_2;

//     calc == {
//         a_1 * a_2 - b_1 * b_2;
//         ==
//         (n * k_1 + b_1) * (n * k_2 + b_2) - b_1 * b_2;
//         ==
//         n * n * k_1 * k_2 + n * b_1 * k_2 + n * k_1 * b_2;
//         ==
//         {
//             assert n * b_1 * k_2 == n * (b_1 * k_2);
//             assert n * k_1 * b_2 == n * (k_1 * b_2);
//             assert n * n * k_1 * k_2 == n * (n * k_1 * k_2); // order of these asserts somehow matter
//         }
//         n * (n * k_1 * k_2) + n * (b_1 * k_2) + n * (k_1 * b_2);
//         ==
//         {
//             mul_distrubtive_lema(n, n * k_1 * k_2, b_1 * k_2, k_1 * b_2);
//         }
//         n * (n * k_1 * k_2 + b_1 * k_2 + k_1 * b_2);
//     }
//     ghost var k := n * k_1 * k_2 + b_1 * k_2 + k_1 * b_2;
//     assert a_1 * a_2 - b_1 * b_2 == n * k;
//     assert congruent_def(a_1 * a_2, b_1 * b_2, n);
// }

// lemma {:induction e} mod_exp_lema(b: int, e: nat, m: nat)
//     requires m >= 2;
//     ensures power(b, e) % m == (power(b % m , e)) % m
// {
//     if e == 0 {
//         assert true;
//     } else {
//         assert power(b, e - 1) % m == (power(b % m , e - 1)) % m;
//         assume false;
//     }
// }


}