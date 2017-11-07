module dmd.PREC;

import dmd.common;
import dmd.TOK;

/**********************************
 * Set operator precedence for each operator.
 */

// Operator precedence - greater values are higher precedence

enum PREC
{
    PREC_zero,
    PREC_expr,
    PREC_assign,
    PREC_cond,
    PREC_oror,
    PREC_andand,
    PREC_or,
    PREC_xor,
    PREC_and,
    PREC_equal,
    PREC_rel,
    PREC_shift,
    PREC_add,
    PREC_mul,
    PREC_pow,
    PREC_unary,
    PREC_primary,
}

__gshared PREC[TOK.TOKMAX] precedence;

import dmd.EnumUtils;
mixin(BringToCurrentScope!(PREC));