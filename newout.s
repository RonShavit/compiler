;;; prologue-1.asm
;;; The first part of the standard prologue for compiled programs
;;;
;;; Programmer: Mayer Goldberg, 2023

%define T_void 				0
%define T_nil 				1
%define T_char 				2
%define T_string 			3
%define T_closure 			4
%define T_undefined			5
%define T_boolean 			8
%define T_boolean_false 		(T_boolean | 1)
%define T_boolean_true 			(T_boolean | 2)
%define T_number 			16
%define T_integer			(T_number | 1)
%define T_fraction 			(T_number | 2)
%define T_real 				(T_number | 3)
%define T_collection 			32
%define T_pair 				(T_collection | 1)
%define T_vector 			(T_collection | 2)
%define T_symbol 			64
%define T_interned_symbol		(T_symbol | 1)
%define T_uninterned_symbol		(T_symbol | 2)

%define SOB_CHAR_VALUE(reg) 		byte [reg + 1]
%define SOB_PAIR_CAR(reg)		qword [reg + 1]
%define SOB_PAIR_CDR(reg)		qword [reg + 1 + 8]
%define SOB_STRING_LENGTH(reg)		qword [reg + 1]
%define SOB_VECTOR_LENGTH(reg)		qword [reg + 1]
%define SOB_CLOSURE_ENV(reg)		qword [reg + 1]
%define SOB_CLOSURE_CODE(reg)		qword [reg + 1 + 8]

%define OLD_RBP 			qword [rbp]
%define RET_ADDR 			qword [rbp + 8 * 1]
%define ENV 				qword [rbp + 8 * 2]
%define COUNT 				qword [rbp + 8 * 3]
%define PARAM(n) 			qword [rbp + 8 * (4 + n)]
%define AND_KILL_FRAME(n)		(8 * (2 + n))

%define MAGIC				496351

%macro ENTER 0
	enter 0, 0
	and rsp, ~15
%endmacro

%macro LEAVE 0
	leave
%endmacro

%macro assert_type 2
        cmp byte [%1], %2
        jne L_error_incorrect_type
%endmacro

%define assert_void(reg)		assert_type reg, T_void
%define assert_nil(reg)			assert_type reg, T_nil
%define assert_char(reg)		assert_type reg, T_char
%define assert_string(reg)		assert_type reg, T_string
%define assert_symbol(reg)		assert_type reg, T_symbol
%define assert_interned_symbol(reg)	assert_type reg, T_interned_symbol
%define assert_uninterned_symbol(reg)	assert_type reg, T_uninterned_symbol
%define assert_closure(reg)		assert_type reg, T_closure
%define assert_boolean(reg)		assert_type reg, T_boolean
%define assert_integer(reg)		assert_type reg, T_integer
%define assert_fraction(reg)		assert_type reg, T_fraction
%define assert_real(reg)		assert_type reg, T_real
%define assert_pair(reg)		assert_type reg, T_pair
%define assert_vector(reg)		assert_type reg, T_vector

%define sob_void			(L_constants + 0)
%define sob_nil				(L_constants + 1)
%define sob_boolean_false		(L_constants + 2)
%define sob_boolean_true		(L_constants + 3)
%define sob_char_nul			(L_constants + 4)

%define bytes(n)			(n)
%define kbytes(n) 			(bytes(n) << 10)
%define mbytes(n) 			(kbytes(n) << 10)
%define gbytes(n) 			(mbytes(n) << 10)

section .data
L_constants:
	; L_constants + 0:
	db T_void
	; L_constants + 1:
	db T_nil
	; L_constants + 2:
	db T_boolean_false
	; L_constants + 3:
	db T_boolean_true
	; L_constants + 4:
	db T_char, 0x00	; #\nul
	; L_constants + 6:
	db T_string	; "null?"
	dq 5
	db 0x6E, 0x75, 0x6C, 0x6C, 0x3F
	; L_constants + 20:
	db T_string	; "pair?"
	dq 5
	db 0x70, 0x61, 0x69, 0x72, 0x3F
	; L_constants + 34:
	db T_string	; "void?"
	dq 5
	db 0x76, 0x6F, 0x69, 0x64, 0x3F
	; L_constants + 48:
	db T_string	; "char?"
	dq 5
	db 0x63, 0x68, 0x61, 0x72, 0x3F
	; L_constants + 62:
	db T_string	; "string?"
	dq 7
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3F
	; L_constants + 78:
	db T_string	; "interned-symbol?"
	dq 16
	db 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x65, 0x64
	db 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 103:
	db T_string	; "vector?"
	dq 7
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x3F
	; L_constants + 119:
	db T_string	; "procedure?"
	dq 10
	db 0x70, 0x72, 0x6F, 0x63, 0x65, 0x64, 0x75, 0x72
	db 0x65, 0x3F
	; L_constants + 138:
	db T_string	; "real?"
	dq 5
	db 0x72, 0x65, 0x61, 0x6C, 0x3F
	; L_constants + 152:
	db T_string	; "fraction?"
	dq 9
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x3F
	; L_constants + 170:
	db T_string	; "boolean?"
	dq 8
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x3F
	; L_constants + 187:
	db T_string	; "number?"
	dq 7
	db 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x3F
	; L_constants + 203:
	db T_string	; "collection?"
	dq 11
	db 0x63, 0x6F, 0x6C, 0x6C, 0x65, 0x63, 0x74, 0x69
	db 0x6F, 0x6E, 0x3F
	; L_constants + 223:
	db T_string	; "cons"
	dq 4
	db 0x63, 0x6F, 0x6E, 0x73
	; L_constants + 236:
	db T_string	; "display-sexpr"
	dq 13
	db 0x64, 0x69, 0x73, 0x70, 0x6C, 0x61, 0x79, 0x2D
	db 0x73, 0x65, 0x78, 0x70, 0x72
	; L_constants + 258:
	db T_string	; "write-char"
	dq 10
	db 0x77, 0x72, 0x69, 0x74, 0x65, 0x2D, 0x63, 0x68
	db 0x61, 0x72
	; L_constants + 277:
	db T_string	; "car"
	dq 3
	db 0x63, 0x61, 0x72
	; L_constants + 289:
	db T_string	; "cdr"
	dq 3
	db 0x63, 0x64, 0x72
	; L_constants + 301:
	db T_string	; "string-length"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 323:
	db T_string	; "vector-length"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 345:
	db T_string	; "real->integer"
	dq 13
	db 0x72, 0x65, 0x61, 0x6C, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 367:
	db T_string	; "exit"
	dq 4
	db 0x65, 0x78, 0x69, 0x74
	; L_constants + 380:
	db T_string	; "integer->real"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 402:
	db T_string	; "fraction->real"
	dq 14
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x2D, 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 425:
	db T_string	; "char->integer"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 447:
	db T_string	; "integer->char"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x63, 0x68, 0x61, 0x72
	; L_constants + 469:
	db T_string	; "trng"
	dq 4
	db 0x74, 0x72, 0x6E, 0x67
	; L_constants + 482:
	db T_string	; "zero?"
	dq 5
	db 0x7A, 0x65, 0x72, 0x6F, 0x3F
	; L_constants + 496:
	db T_string	; "integer?"
	dq 8
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x3F
	; L_constants + 513:
	db T_string	; "__bin-apply"
	dq 11
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x70
	db 0x70, 0x6C, 0x79
	; L_constants + 533:
	db T_string	; "__bin-add-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x72, 0x72
	; L_constants + 554:
	db T_string	; "__bin-sub-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x72, 0x72
	; L_constants + 575:
	db T_string	; "__bin-mul-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 596:
	db T_string	; "__bin-div-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x72, 0x72
	; L_constants + 617:
	db T_string	; "__bin-add-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x71, 0x71
	; L_constants + 638:
	db T_string	; "__bin-sub-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x71, 0x71
	; L_constants + 659:
	db T_string	; "__bin-mul-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 680:
	db T_string	; "__bin-div-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x71, 0x71
	; L_constants + 701:
	db T_string	; "__bin-add-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x7A, 0x7A
	; L_constants + 722:
	db T_string	; "__bin-sub-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x7A, 0x7A
	; L_constants + 743:
	db T_string	; "__bin-mul-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 764:
	db T_string	; "__bin-div-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x7A, 0x7A
	; L_constants + 785:
	db T_string	; "error"
	dq 5
	db 0x65, 0x72, 0x72, 0x6F, 0x72
	; L_constants + 799:
	db T_string	; "__bin-less-than-rr"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x72, 0x72
	; L_constants + 826:
	db T_string	; "__bin-less-than-qq"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x71, 0x71
	; L_constants + 853:
	db T_string	; "__bin-less-than-zz"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x7A, 0x7A
	; L_constants + 880:
	db T_string	; "__bin-equal-rr"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 903:
	db T_string	; "__bin-equal-qq"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 926:
	db T_string	; "__bin-equal-zz"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 949:
	db T_string	; "quotient"
	dq 8
	db 0x71, 0x75, 0x6F, 0x74, 0x69, 0x65, 0x6E, 0x74
	; L_constants + 966:
	db T_string	; "remainder"
	dq 9
	db 0x72, 0x65, 0x6D, 0x61, 0x69, 0x6E, 0x64, 0x65
	db 0x72
	; L_constants + 984:
	db T_string	; "set-car!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x61, 0x72, 0x21
	; L_constants + 1001:
	db T_string	; "set-cdr!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x64, 0x72, 0x21
	; L_constants + 1018:
	db T_string	; "string-ref"
	dq 10
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1037:
	db T_string	; "vector-ref"
	dq 10
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1056:
	db T_string	; "vector-set!"
	dq 11
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1076:
	db T_string	; "string-set!"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1096:
	db T_string	; "make-vector"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72
	; L_constants + 1116:
	db T_string	; "make-string"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67
	; L_constants + 1136:
	db T_string	; "numerator"
	dq 9
	db 0x6E, 0x75, 0x6D, 0x65, 0x72, 0x61, 0x74, 0x6F
	db 0x72
	; L_constants + 1154:
	db T_string	; "denominator"
	dq 11
	db 0x64, 0x65, 0x6E, 0x6F, 0x6D, 0x69, 0x6E, 0x61
	db 0x74, 0x6F, 0x72
	; L_constants + 1174:
	db T_string	; "eq?"
	dq 3
	db 0x65, 0x71, 0x3F
	; L_constants + 1186:
	db T_string	; "__integer-to-fracti...
	dq 21
	db 0x5F, 0x5F, 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65
	db 0x72, 0x2D, 0x74, 0x6F, 0x2D, 0x66, 0x72, 0x61
	db 0x63, 0x74, 0x69, 0x6F, 0x6E
	; L_constants + 1216:
	db T_string	; "logand"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x61, 0x6E, 0x64
	; L_constants + 1231:
	db T_string	; "logor"
	dq 5
	db 0x6C, 0x6F, 0x67, 0x6F, 0x72
	; L_constants + 1245:
	db T_string	; "logxor"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x78, 0x6F, 0x72
	; L_constants + 1260:
	db T_string	; "lognot"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x6E, 0x6F, 0x74
	; L_constants + 1275:
	db T_string	; "ash"
	dq 3
	db 0x61, 0x73, 0x68
	; L_constants + 1287:
	db T_string	; "symbol?"
	dq 7
	db 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 1303:
	db T_string	; "uninterned-symbol?"
	dq 18
	db 0x75, 0x6E, 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E
	db 0x65, 0x64, 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F
	db 0x6C, 0x3F
	; L_constants + 1330:
	db T_string	; "gensym?"
	dq 7
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D, 0x3F
	; L_constants + 1346:
	db T_string	; "gensym"
	dq 6
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D
	; L_constants + 1361:
	db T_string	; "frame"
	dq 5
	db 0x66, 0x72, 0x61, 0x6D, 0x65
	; L_constants + 1375:
	db T_string	; "break"
	dq 5
	db 0x62, 0x72, 0x65, 0x61, 0x6B
	; L_constants + 1389:
	db T_string	; "boolean-false?"
	dq 14
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x66, 0x61, 0x6C, 0x73, 0x65, 0x3F
	; L_constants + 1412:
	db T_string	; "boolean-true?"
	dq 13
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x74, 0x72, 0x75, 0x65, 0x3F
	; L_constants + 1434:
	db T_string	; "primitive?"
	dq 10
	db 0x70, 0x72, 0x69, 0x6D, 0x69, 0x74, 0x69, 0x76
	db 0x65, 0x3F
	; L_constants + 1453:
	db T_string	; "length"
	dq 6
	db 0x6C, 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 1468:
	db T_string	; "make-list"
	dq 9
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74
	; L_constants + 1486:
	db T_string	; "return"
	dq 6
	db 0x72, 0x65, 0x74, 0x75, 0x72, 0x6E
	; L_constants + 1501:
	db T_string	; "caar"
	dq 4
	db 0x63, 0x61, 0x61, 0x72
	; L_constants + 1514:
	db T_string	; "cadr"
	dq 4
	db 0x63, 0x61, 0x64, 0x72
	; L_constants + 1527:
	db T_string	; "cdar"
	dq 4
	db 0x63, 0x64, 0x61, 0x72
	; L_constants + 1540:
	db T_string	; "cddr"
	dq 4
	db 0x63, 0x64, 0x64, 0x72
	; L_constants + 1553:
	db T_string	; "caaar"
	dq 5
	db 0x63, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1567:
	db T_string	; "caadr"
	dq 5
	db 0x63, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1581:
	db T_string	; "cadar"
	dq 5
	db 0x63, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1595:
	db T_string	; "caddr"
	dq 5
	db 0x63, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1609:
	db T_string	; "cdaar"
	dq 5
	db 0x63, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1623:
	db T_string	; "cdadr"
	dq 5
	db 0x63, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1637:
	db T_string	; "cddar"
	dq 5
	db 0x63, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1651:
	db T_string	; "cdddr"
	dq 5
	db 0x63, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1665:
	db T_string	; "caaaar"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1680:
	db T_string	; "caaadr"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1695:
	db T_string	; "caadar"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1710:
	db T_string	; "caaddr"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1725:
	db T_string	; "cadaar"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1740:
	db T_string	; "cadadr"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1755:
	db T_string	; "caddar"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1770:
	db T_string	; "cadddr"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1785:
	db T_string	; "cdaaar"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1800:
	db T_string	; "cdaadr"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1815:
	db T_string	; "cdadar"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1830:
	db T_string	; "cdaddr"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1845:
	db T_string	; "cddaar"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1860:
	db T_string	; "cddadr"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1875:
	db T_string	; "cdddar"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1890:
	db T_string	; "cddddr"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1905:
	db T_string	; "list?"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x3F
	; L_constants + 1919:
	db T_string	; "list"
	dq 4
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 1932:
	db T_string	; "not"
	dq 3
	db 0x6E, 0x6F, 0x74
	; L_constants + 1944:
	db T_string	; "rational?"
	dq 9
	db 0x72, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x61, 0x6C
	db 0x3F
	; L_constants + 1962:
	db T_string	; "list*"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x2A
	; L_constants + 1976:
	db T_string	; "whatever"
	dq 8
	db 0x77, 0x68, 0x61, 0x74, 0x65, 0x76, 0x65, 0x72
	; L_constants + 1993:
	db T_interned_symbol	; whatever
	dq L_constants + 1976
	; L_constants + 2002:
	db T_string	; "with"
	dq 4
	db 0x77, 0x69, 0x74, 0x68
	; L_constants + 2015:
	db T_string	; "apply"
	dq 5
	db 0x61, 0x70, 0x70, 0x6C, 0x79
	; L_constants + 2029:
	db T_string	; "ormap"
	dq 5
	db 0x6F, 0x72, 0x6D, 0x61, 0x70
	; L_constants + 2043:
	db T_string	; "map"
	dq 3
	db 0x6D, 0x61, 0x70
	; L_constants + 2055:
	db T_string	; "andmap"
	dq 6
	db 0x61, 0x6E, 0x64, 0x6D, 0x61, 0x70
	; L_constants + 2070:
	db T_string	; "reverse"
	dq 7
	db 0x72, 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 2086:
	db T_string	; "fold-left"
	dq 9
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x6C, 0x65, 0x66
	db 0x74
	; L_constants + 2104:
	db T_string	; "append"
	dq 6
	db 0x61, 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2119:
	db T_string	; "fold-right"
	dq 10
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x72, 0x69, 0x67
	db 0x68, 0x74
	; L_constants + 2138:
	db T_string	; "+"
	dq 1
	db 0x2B
	; L_constants + 2148:
	db T_interned_symbol	; +
	dq L_constants + 2138
	; L_constants + 2157:
	db T_string	; "all arguments need ...
	dq 32
	db 0x61, 0x6C, 0x6C, 0x20, 0x61, 0x72, 0x67, 0x75
	db 0x6D, 0x65, 0x6E, 0x74, 0x73, 0x20, 0x6E, 0x65
	db 0x65, 0x64, 0x20, 0x74, 0x6F, 0x20, 0x62, 0x65
	db 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x73
	; L_constants + 2198:
	db T_string	; "__bin_integer_to_fr...
	dq 25
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x5F, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72, 0x5F, 0x74, 0x6F
	db 0x5F, 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F
	db 0x6E
	; L_constants + 2232:
	db T_integer	; 0
	dq 0
	; L_constants + 2241:
	db T_string	; "-"
	dq 1
	db 0x2D
	; L_constants + 2251:
	db T_interned_symbol	; -
	dq L_constants + 2241
	; L_constants + 2260:
	db T_string	; "real"
	dq 4
	db 0x72, 0x65, 0x61, 0x6C
	; L_constants + 2273:
	db T_string	; "*"
	dq 1
	db 0x2A
	; L_constants + 2283:
	db T_interned_symbol	; *
	dq L_constants + 2273
	; L_constants + 2292:
	db T_integer	; 1
	dq 1
	; L_constants + 2301:
	db T_string	; "/"
	dq 1
	db 0x2F
	; L_constants + 2311:
	db T_interned_symbol	; /
	dq L_constants + 2301
	; L_constants + 2320:
	db T_string	; "fact"
	dq 4
	db 0x66, 0x61, 0x63, 0x74
	; L_constants + 2333:
	db T_string	; "<"
	dq 1
	db 0x3C
	; L_constants + 2343:
	db T_string	; "<="
	dq 2
	db 0x3C, 0x3D
	; L_constants + 2354:
	db T_string	; ">"
	dq 1
	db 0x3E
	; L_constants + 2364:
	db T_string	; ">="
	dq 2
	db 0x3E, 0x3D
	; L_constants + 2375:
	db T_string	; "="
	dq 1
	db 0x3D
	; L_constants + 2385:
	db T_string	; "generic-comparator"
	dq 18
	db 0x67, 0x65, 0x6E, 0x65, 0x72, 0x69, 0x63, 0x2D
	db 0x63, 0x6F, 0x6D, 0x70, 0x61, 0x72, 0x61, 0x74
	db 0x6F, 0x72
	; L_constants + 2412:
	db T_interned_symbol	; generic-comparator
	dq L_constants + 2385
	; L_constants + 2421:
	db T_string	; "all the arguments m...
	dq 33
	db 0x61, 0x6C, 0x6C, 0x20, 0x74, 0x68, 0x65, 0x20
	db 0x61, 0x72, 0x67, 0x75, 0x6D, 0x65, 0x6E, 0x74
	db 0x73, 0x20, 0x6D, 0x75, 0x73, 0x74, 0x20, 0x62
	db 0x65, 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72
	db 0x73
	; L_constants + 2463:
	db T_string	; "char<?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3F
	; L_constants + 2478:
	db T_string	; "char<=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3D, 0x3F
	; L_constants + 2494:
	db T_string	; "char=?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3D, 0x3F
	; L_constants + 2509:
	db T_string	; "char>?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3F
	; L_constants + 2524:
	db T_string	; "char>=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3D, 0x3F
	; L_constants + 2540:
	db T_string	; "char-downcase"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x64, 0x6F, 0x77
	db 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2562:
	db T_string	; "char-upcase"
	dq 11
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x75, 0x70, 0x63
	db 0x61, 0x73, 0x65
	; L_constants + 2582:
	db T_interned_symbol	; make-vector
	dq L_constants + 1096
	; L_constants + 2591:
	db T_string	; "Usage: (make-vector...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 2643:
	db T_interned_symbol	; make-string
	dq L_constants + 1116
	; L_constants + 2652:
	db T_string	; "Usage: (make-string...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 2704:
	db T_string	; "list->vector"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x76, 0x65
	db 0x63, 0x74, 0x6F, 0x72
	; L_constants + 2725:
	db T_string	; "list->string"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x73, 0x74
	db 0x72, 0x69, 0x6E, 0x67
	; L_constants + 2746:
	db T_string	; "vector"
	dq 6
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72
	; L_constants + 2761:
	db T_string	; "string->list"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 2782:
	db T_string	; "vector->list"
	dq 12
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 2803:
	db T_string	; "random"
	dq 6
	db 0x72, 0x61, 0x6E, 0x64, 0x6F, 0x6D
	; L_constants + 2818:
	db T_string	; "positive?"
	dq 9
	db 0x70, 0x6F, 0x73, 0x69, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 2836:
	db T_string	; "negative?"
	dq 9
	db 0x6E, 0x65, 0x67, 0x61, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 2854:
	db T_string	; "even?"
	dq 5
	db 0x65, 0x76, 0x65, 0x6E, 0x3F
	; L_constants + 2868:
	db T_integer	; 2
	dq 2
	; L_constants + 2877:
	db T_string	; "odd?"
	dq 4
	db 0x6F, 0x64, 0x64, 0x3F
	; L_constants + 2890:
	db T_string	; "abs"
	dq 3
	db 0x61, 0x62, 0x73
	; L_constants + 2902:
	db T_string	; "equal?"
	dq 6
	db 0x65, 0x71, 0x75, 0x61, 0x6C, 0x3F
	; L_constants + 2917:
	db T_string	; "string=?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3D, 0x3F
	; L_constants + 2934:
	db T_string	; "assoc"
	dq 5
	db 0x61, 0x73, 0x73, 0x6F, 0x63
	; L_constants + 2948:
	db T_string	; "string-append"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2970:
	db T_string	; "vector-append"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2992:
	db T_string	; "string-reverse"
	dq 14
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3015:
	db T_string	; "vector-reverse"
	dq 14
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3038:
	db T_string	; "string-reverse!"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3062:
	db T_string	; "vector-reverse!"
	dq 15
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3086:
	db T_string	; "make-list-generator...
	dq 19
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74, 0x2D, 0x67, 0x65, 0x6E, 0x65, 0x72, 0x61
	db 0x74, 0x6F, 0x72
	; L_constants + 3114:
	db T_string	; "make-string-generat...
	dq 21
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x2D, 0x67, 0x65, 0x6E, 0x65
	db 0x72, 0x61, 0x74, 0x6F, 0x72
	; L_constants + 3144:
	db T_string	; "make-vector-generat...
	dq 21
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x2D, 0x67, 0x65, 0x6E, 0x65
	db 0x72, 0x61, 0x74, 0x6F, 0x72
	; L_constants + 3174:
	db T_string	; "logarithm"
	dq 9
	db 0x6C, 0x6F, 0x67, 0x61, 0x72, 0x69, 0x74, 0x68
	db 0x6D
	; L_constants + 3192:
	db T_real	; 1.000000
	dq 1.000000
	; L_constants + 3201:
	db T_string	; "newline"
	dq 7
	db 0x6E, 0x65, 0x77, 0x6C, 0x69, 0x6E, 0x65
	; L_constants + 3217:
	db T_char, 0x0A	; #\newline
	; L_constants + 3219:
	db T_string	; "void"
	dq 4
	db 0x76, 0x6F, 0x69, 0x64
	; L_constants + 3232:
	db T_integer	; 3
	dq 3
free_var_0:	; location of *
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2273

free_var_1:	; location of +
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2138

free_var_2:	; location of -
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2241

free_var_3:	; location of /
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2301

free_var_4:	; location of <
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2333

free_var_5:	; location of <=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2343

free_var_6:	; location of =
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2375

free_var_7:	; location of >
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2354

free_var_8:	; location of >=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2364

free_var_9:	; location of __bin-add-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 617

free_var_10:	; location of __bin-add-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 533

free_var_11:	; location of __bin-add-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 701

free_var_12:	; location of __bin-apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 513

free_var_13:	; location of __bin-div-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 680

free_var_14:	; location of __bin-div-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 596

free_var_15:	; location of __bin-div-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 764

free_var_16:	; location of __bin-equal-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 903

free_var_17:	; location of __bin-equal-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 880

free_var_18:	; location of __bin-equal-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 926

free_var_19:	; location of __bin-less-than-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 826

free_var_20:	; location of __bin-less-than-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 799

free_var_21:	; location of __bin-less-than-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 853

free_var_22:	; location of __bin-mul-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 659

free_var_23:	; location of __bin-mul-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 575

free_var_24:	; location of __bin-mul-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 743

free_var_25:	; location of __bin-sub-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 638

free_var_26:	; location of __bin-sub-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 554

free_var_27:	; location of __bin-sub-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 722

free_var_28:	; location of __bin_integer_to_fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2198

free_var_29:	; location of __integer-to-fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1186

free_var_30:	; location of abs
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2890

free_var_31:	; location of andmap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2055

free_var_32:	; location of append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2104

free_var_33:	; location of apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2015

free_var_34:	; location of assoc
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2934

free_var_35:	; location of caaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1665

free_var_36:	; location of caaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1680

free_var_37:	; location of caaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1553

free_var_38:	; location of caadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1695

free_var_39:	; location of caaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1710

free_var_40:	; location of caadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1567

free_var_41:	; location of caar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1501

free_var_42:	; location of cadaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1725

free_var_43:	; location of cadadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1740

free_var_44:	; location of cadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1581

free_var_45:	; location of caddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1755

free_var_46:	; location of cadddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1770

free_var_47:	; location of caddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1595

free_var_48:	; location of cadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1514

free_var_49:	; location of car
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 277

free_var_50:	; location of cdaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1785

free_var_51:	; location of cdaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1800

free_var_52:	; location of cdaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1609

free_var_53:	; location of cdadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1815

free_var_54:	; location of cdaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1830

free_var_55:	; location of cdadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1623

free_var_56:	; location of cdar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1527

free_var_57:	; location of cddaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1845

free_var_58:	; location of cddadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1860

free_var_59:	; location of cddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1637

free_var_60:	; location of cdddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1875

free_var_61:	; location of cddddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1890

free_var_62:	; location of cdddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1651

free_var_63:	; location of cddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1540

free_var_64:	; location of cdr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 289

free_var_65:	; location of char->integer
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 425

free_var_66:	; location of char-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2540

free_var_67:	; location of char-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2562

free_var_68:	; location of char<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2478

free_var_69:	; location of char<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2463

free_var_70:	; location of char=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2494

free_var_71:	; location of char>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2524

free_var_72:	; location of char>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2509

free_var_73:	; location of char?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 48

free_var_74:	; location of cons
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 223

free_var_75:	; location of eq?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1174

free_var_76:	; location of equal?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2902

free_var_77:	; location of error
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 785

free_var_78:	; location of even?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2854

free_var_79:	; location of fact
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2320

free_var_80:	; location of fold-left
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2086

free_var_81:	; location of fold-right
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2119

free_var_82:	; location of fraction->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 402

free_var_83:	; location of fraction?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 152

free_var_84:	; location of integer->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 380

free_var_85:	; location of integer?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 496

free_var_86:	; location of list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1919

free_var_87:	; location of list*
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1962

free_var_88:	; location of list->string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2725

free_var_89:	; location of list->vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2704

free_var_90:	; location of list?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1905

free_var_91:	; location of logarithm
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3174

free_var_92:	; location of make-list-generator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3086

free_var_93:	; location of make-string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1116

free_var_94:	; location of make-string-generator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3114

free_var_95:	; location of make-vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1096

free_var_96:	; location of make-vector-generator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3144

free_var_97:	; location of map
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2043

free_var_98:	; location of negative?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2836

free_var_99:	; location of newline
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3201

free_var_100:	; location of not
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1932

free_var_101:	; location of null?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 6

free_var_102:	; location of number?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 187

free_var_103:	; location of odd?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2877

free_var_104:	; location of ormap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2029

free_var_105:	; location of pair?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 20

free_var_106:	; location of positive?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2818

free_var_107:	; location of random
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2803

free_var_108:	; location of rational?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1944

free_var_109:	; location of real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2260

free_var_110:	; location of real?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 138

free_var_111:	; location of remainder
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 966

free_var_112:	; location of reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2070

free_var_113:	; location of string->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2761

free_var_114:	; location of string-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2948

free_var_115:	; location of string-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 301

free_var_116:	; location of string-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1018

free_var_117:	; location of string-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2992

free_var_118:	; location of string-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3038

free_var_119:	; location of string-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1076

free_var_120:	; location of string=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2917

free_var_121:	; location of string?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 62

free_var_122:	; location of trng
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 469

free_var_123:	; location of vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2746

free_var_124:	; location of vector->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2782

free_var_125:	; location of vector-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2970

free_var_126:	; location of vector-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 323

free_var_127:	; location of vector-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1037

free_var_128:	; location of vector-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3015

free_var_129:	; location of vector-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3062

free_var_130:	; location of vector-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1056

free_var_131:	; location of vector?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 103

free_var_132:	; location of void
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3219

free_var_133:	; location of with
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2002

free_var_134:	; location of write-char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 258

free_var_135:	; location of zero?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 482


extern printf, fprintf, stdout, stderr, fwrite, exit, putchar, getchar
global main
section .text
main:
        enter 0, 0
        push 0
        push 0
        push Lend
        enter 0, 0
	; building closure for null?
	mov rdi, free_var_101
	mov rsi, L_code_ptr_is_null
	call bind_primitive

	; building closure for pair?
	mov rdi, free_var_105
	mov rsi, L_code_ptr_is_pair
	call bind_primitive

	; building closure for char?
	mov rdi, free_var_73
	mov rsi, L_code_ptr_is_char
	call bind_primitive

	; building closure for string?
	mov rdi, free_var_121
	mov rsi, L_code_ptr_is_string
	call bind_primitive

	; building closure for vector?
	mov rdi, free_var_131
	mov rsi, L_code_ptr_is_vector
	call bind_primitive

	; building closure for real?
	mov rdi, free_var_110
	mov rsi, L_code_ptr_is_real
	call bind_primitive

	; building closure for fraction?
	mov rdi, free_var_83
	mov rsi, L_code_ptr_is_fraction
	call bind_primitive

	; building closure for number?
	mov rdi, free_var_102
	mov rsi, L_code_ptr_is_number
	call bind_primitive

	; building closure for cons
	mov rdi, free_var_74
	mov rsi, L_code_ptr_cons
	call bind_primitive

	; building closure for write-char
	mov rdi, free_var_134
	mov rsi, L_code_ptr_write_char
	call bind_primitive

	; building closure for car
	mov rdi, free_var_49
	mov rsi, L_code_ptr_car
	call bind_primitive

	; building closure for cdr
	mov rdi, free_var_64
	mov rsi, L_code_ptr_cdr
	call bind_primitive

	; building closure for string-length
	mov rdi, free_var_115
	mov rsi, L_code_ptr_string_length
	call bind_primitive

	; building closure for vector-length
	mov rdi, free_var_126
	mov rsi, L_code_ptr_vector_length
	call bind_primitive

	; building closure for integer->real
	mov rdi, free_var_84
	mov rsi, L_code_ptr_integer_to_real
	call bind_primitive

	; building closure for fraction->real
	mov rdi, free_var_82
	mov rsi, L_code_ptr_fraction_to_real
	call bind_primitive

	; building closure for char->integer
	mov rdi, free_var_65
	mov rsi, L_code_ptr_char_to_integer
	call bind_primitive

	; building closure for trng
	mov rdi, free_var_122
	mov rsi, L_code_ptr_trng
	call bind_primitive

	; building closure for zero?
	mov rdi, free_var_135
	mov rsi, L_code_ptr_is_zero
	call bind_primitive

	; building closure for integer?
	mov rdi, free_var_85
	mov rsi, L_code_ptr_is_integer
	call bind_primitive

	; building closure for __bin-apply
	mov rdi, free_var_12
	mov rsi, L_code_ptr_bin_apply
	call bind_primitive

	; building closure for __bin-add-rr
	mov rdi, free_var_10
	mov rsi, L_code_ptr_raw_bin_add_rr
	call bind_primitive

	; building closure for __bin-sub-rr
	mov rdi, free_var_26
	mov rsi, L_code_ptr_raw_bin_sub_rr
	call bind_primitive

	; building closure for __bin-mul-rr
	mov rdi, free_var_23
	mov rsi, L_code_ptr_raw_bin_mul_rr
	call bind_primitive

	; building closure for __bin-div-rr
	mov rdi, free_var_14
	mov rsi, L_code_ptr_raw_bin_div_rr
	call bind_primitive

	; building closure for __bin-add-qq
	mov rdi, free_var_9
	mov rsi, L_code_ptr_raw_bin_add_qq
	call bind_primitive

	; building closure for __bin-sub-qq
	mov rdi, free_var_25
	mov rsi, L_code_ptr_raw_bin_sub_qq
	call bind_primitive

	; building closure for __bin-mul-qq
	mov rdi, free_var_22
	mov rsi, L_code_ptr_raw_bin_mul_qq
	call bind_primitive

	; building closure for __bin-div-qq
	mov rdi, free_var_13
	mov rsi, L_code_ptr_raw_bin_div_qq
	call bind_primitive

	; building closure for __bin-add-zz
	mov rdi, free_var_11
	mov rsi, L_code_ptr_raw_bin_add_zz
	call bind_primitive

	; building closure for __bin-sub-zz
	mov rdi, free_var_27
	mov rsi, L_code_ptr_raw_bin_sub_zz
	call bind_primitive

	; building closure for __bin-mul-zz
	mov rdi, free_var_24
	mov rsi, L_code_ptr_raw_bin_mul_zz
	call bind_primitive

	; building closure for __bin-div-zz
	mov rdi, free_var_15
	mov rsi, L_code_ptr_raw_bin_div_zz
	call bind_primitive

	; building closure for error
	mov rdi, free_var_77
	mov rsi, L_code_ptr_error
	call bind_primitive

	; building closure for __bin-less-than-rr
	mov rdi, free_var_20
	mov rsi, L_code_ptr_raw_less_than_rr
	call bind_primitive

	; building closure for __bin-less-than-qq
	mov rdi, free_var_19
	mov rsi, L_code_ptr_raw_less_than_qq
	call bind_primitive

	; building closure for __bin-less-than-zz
	mov rdi, free_var_21
	mov rsi, L_code_ptr_raw_less_than_zz
	call bind_primitive

	; building closure for __bin-equal-rr
	mov rdi, free_var_17
	mov rsi, L_code_ptr_raw_equal_rr
	call bind_primitive

	; building closure for __bin-equal-qq
	mov rdi, free_var_16
	mov rsi, L_code_ptr_raw_equal_qq
	call bind_primitive

	; building closure for __bin-equal-zz
	mov rdi, free_var_18
	mov rsi, L_code_ptr_raw_equal_zz
	call bind_primitive

	; building closure for remainder
	mov rdi, free_var_111
	mov rsi, L_code_ptr_remainder
	call bind_primitive

	; building closure for string-ref
	mov rdi, free_var_116
	mov rsi, L_code_ptr_string_ref
	call bind_primitive

	; building closure for vector-ref
	mov rdi, free_var_127
	mov rsi, L_code_ptr_vector_ref
	call bind_primitive

	; building closure for vector-set!
	mov rdi, free_var_130
	mov rsi, L_code_ptr_vector_set
	call bind_primitive

	; building closure for string-set!
	mov rdi, free_var_119
	mov rsi, L_code_ptr_string_set
	call bind_primitive

	; building closure for make-vector
	mov rdi, free_var_95
	mov rsi, L_code_ptr_make_vector
	call bind_primitive

	; building closure for make-string
	mov rdi, free_var_93
	mov rsi, L_code_ptr_make_string
	call bind_primitive

	; building closure for eq?
	mov rdi, free_var_75
	mov rsi, L_code_ptr_is_eq
	call bind_primitive

	; building closure for __integer-to-fraction
	mov rdi, free_var_29
	mov rsi, L_code_ptr_integer_to_fraction
	call bind_primitive

	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_008f
	jmp .L_lambda_simple_end_008f
.L_lambda_simple_code_008f:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_008f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_008f:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_008f:	; new closure is in rax
	mov qword [free_var_41], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0090
	jmp .L_lambda_simple_end_0090
.L_lambda_simple_code_0090:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0090
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0090:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0090:	; new closure is in rax
	mov qword [free_var_48], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0091
	jmp .L_lambda_simple_end_0091
.L_lambda_simple_code_0091:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0091
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0091:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0091:	; new closure is in rax
	mov qword [free_var_56], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0092
	jmp .L_lambda_simple_end_0092
.L_lambda_simple_code_0092:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0092
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0092:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0092:	; new closure is in rax
	mov qword [free_var_63], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0093
	jmp .L_lambda_simple_end_0093
.L_lambda_simple_code_0093:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0093
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0093:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0093:	; new closure is in rax
	mov qword [free_var_37], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0094
	jmp .L_lambda_simple_end_0094
.L_lambda_simple_code_0094:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0094
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0094:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0094:	; new closure is in rax
	mov qword [free_var_40], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0095
	jmp .L_lambda_simple_end_0095
.L_lambda_simple_code_0095:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0095
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0095:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0095:	; new closure is in rax
	mov qword [free_var_44], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0096
	jmp .L_lambda_simple_end_0096
.L_lambda_simple_code_0096:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0096
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0096:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0096:	; new closure is in rax
	mov qword [free_var_47], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0097
	jmp .L_lambda_simple_end_0097
.L_lambda_simple_code_0097:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0097
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0097:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0097:	; new closure is in rax
	mov qword [free_var_52], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0098
	jmp .L_lambda_simple_end_0098
.L_lambda_simple_code_0098:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0098
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0098:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0098:	; new closure is in rax
	mov qword [free_var_55], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0099
	jmp .L_lambda_simple_end_0099
.L_lambda_simple_code_0099:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0099
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0099:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0099:	; new closure is in rax
	mov qword [free_var_59], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_009a
	jmp .L_lambda_simple_end_009a
.L_lambda_simple_code_009a:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_009a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_009a:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_009a:	; new closure is in rax
	mov qword [free_var_62], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_009b
	jmp .L_lambda_simple_end_009b
.L_lambda_simple_code_009b:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_009b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_009b:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_009b:	; new closure is in rax
	mov qword [free_var_35], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_009c
	jmp .L_lambda_simple_end_009c
.L_lambda_simple_code_009c:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_009c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_009c:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_009c:	; new closure is in rax
	mov qword [free_var_36], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_009d
	jmp .L_lambda_simple_end_009d
.L_lambda_simple_code_009d:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_009d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_009d:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_009d:	; new closure is in rax
	mov qword [free_var_38], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_009e
	jmp .L_lambda_simple_end_009e
.L_lambda_simple_code_009e:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_009e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_009e:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_009e:	; new closure is in rax
	mov qword [free_var_39], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_009f
	jmp .L_lambda_simple_end_009f
.L_lambda_simple_code_009f:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_009f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_009f:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_009f:	; new closure is in rax
	mov qword [free_var_42], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00a0
	jmp .L_lambda_simple_end_00a0
.L_lambda_simple_code_00a0:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00a0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00a0:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00a0:	; new closure is in rax
	mov qword [free_var_43], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00a1
	jmp .L_lambda_simple_end_00a1
.L_lambda_simple_code_00a1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00a1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00a1:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00a1:	; new closure is in rax
	mov qword [free_var_45], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00a2
	jmp .L_lambda_simple_end_00a2
.L_lambda_simple_code_00a2:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00a2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00a2:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00a2:	; new closure is in rax
	mov qword [free_var_46], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00a3
	jmp .L_lambda_simple_end_00a3
.L_lambda_simple_code_00a3:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00a3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00a3:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00a3:	; new closure is in rax
	mov qword [free_var_50], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00a4
	jmp .L_lambda_simple_end_00a4
.L_lambda_simple_code_00a4:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00a4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00a4:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00a4:	; new closure is in rax
	mov qword [free_var_51], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00a5
	jmp .L_lambda_simple_end_00a5
.L_lambda_simple_code_00a5:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00a5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00a5:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00a5:	; new closure is in rax
	mov qword [free_var_53], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00a6
	jmp .L_lambda_simple_end_00a6
.L_lambda_simple_code_00a6:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00a6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00a6:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00a6:	; new closure is in rax
	mov qword [free_var_54], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00a7
	jmp .L_lambda_simple_end_00a7
.L_lambda_simple_code_00a7:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00a7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00a7:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00a7:	; new closure is in rax
	mov qword [free_var_57], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00a8
	jmp .L_lambda_simple_end_00a8
.L_lambda_simple_code_00a8:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00a8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00a8:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00a8:	; new closure is in rax
	mov qword [free_var_58], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00a9
	jmp .L_lambda_simple_end_00a9
.L_lambda_simple_code_00a9:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00a9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00a9:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00a9:	; new closure is in rax
	mov qword [free_var_60], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00aa
	jmp .L_lambda_simple_end_00aa
.L_lambda_simple_code_00aa:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00aa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00aa:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00aa:	; new closure is in rax
	mov qword [free_var_61], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ab
	jmp .L_lambda_simple_end_00ab
.L_lambda_simple_code_00ab:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00ab
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ab:
	enter 0, 0
	mov rax, PARAM(0)	; param e
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	jne .L_or_end_0008
	mov rax, PARAM(0)	; param e
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_007a
	mov rax, PARAM(0)	; param e
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_90]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_007a
.L_if_else_007a:
	mov rax, L_constants + 2
.L_if_end_007a:
.L_or_end_0008:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00ab:	; new closure is in rax
	mov qword [free_var_90], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0015
	jmp .L_lambda_opt_end_0015
.L_lambda_opt_code_0015:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var args
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0015:	; new closure is in rax
	mov qword [free_var_86], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ac
	jmp .L_lambda_simple_end_00ac
.L_lambda_simple_code_00ac:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00ac
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ac:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	cmp rax, sob_boolean_false
	je .L_if_else_007b
	mov rax, L_constants + 2
	jmp .L_if_end_007b
.L_if_else_007b:
	mov rax, L_constants + 3
.L_if_end_007b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00ac:	; new closure is in rax
	mov qword [free_var_100], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ad
	jmp .L_lambda_simple_end_00ad
.L_lambda_simple_code_00ad:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00ad
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ad:
	enter 0, 0
	mov rax, PARAM(0)	; param q
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	jne .L_or_end_0009
	mov rax, PARAM(0)	; param q
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_or_end_0009:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00ad:	; new closure is in rax
	mov qword [free_var_108], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ae
	jmp .L_lambda_simple_end_00ae
.L_lambda_simple_code_00ae:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00ae
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ae:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00af
	jmp .L_lambda_simple_end_00af
.L_lambda_simple_code_00af:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00af
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00af:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_007c
	mov rax, PARAM(0)	; param a
	jmp .L_if_end_007c
.L_if_else_007c:
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_007c:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00af:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0016
	jmp .L_lambda_opt_end_0016
.L_lambda_opt_code_0016:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0016:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00ae:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_87], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00b0
	jmp .L_lambda_simple_end_00b0
.L_lambda_simple_code_00b0:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00b0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00b0:
	enter 0, 0
	mov rax, PARAM(1)	; param f
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00b0:	; new closure is in rax
	mov qword [free_var_133], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00b1
	jmp .L_lambda_simple_end_00b1
.L_lambda_simple_code_00b1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00b1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00b1:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00b2
	jmp .L_lambda_simple_end_00b2
.L_lambda_simple_code_00b2:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00b2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00b2:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_007d
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_007d
.L_if_else_007d:
	mov rax, PARAM(0)	; param a
.L_if_end_007d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00b2:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0017
	jmp .L_lambda_opt_end_0017
.L_lambda_opt_code_0017:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param f
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_12]	; free var __bin-apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0017:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00b1:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_33], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0018
	jmp .L_lambda_opt_end_0018
.L_lambda_opt_code_0018:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1 ; push n (num of args)
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00b3
	jmp .L_lambda_simple_end_00b3
.L_lambda_simple_code_00b3:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00b3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00b3:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing loop
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00b4
	jmp .L_lambda_simple_end_00b4
.L_lambda_simple_code_00b4:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00b4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00b4:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_007e
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	jne .L_or_end_000a
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_or_end_000a:
	jmp .L_if_end_007e
.L_if_else_007e:
	mov rax, L_constants + 2
.L_if_end_007e:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00b4:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_007f
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1 ; push n (num of args)
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_007f
.L_if_else_007f:
	mov rax, L_constants + 2
.L_if_end_007f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00b3:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0018:	; new closure is in rax
	mov qword [free_var_104], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0019
	jmp .L_lambda_opt_end_0019
.L_lambda_opt_code_0019:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1 ; push n (num of args)
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00b5
	jmp .L_lambda_simple_end_00b5
.L_lambda_simple_code_00b5:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00b5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00b5:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing loop
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00b6
	jmp .L_lambda_simple_end_00b6
.L_lambda_simple_code_00b6:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00b6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00b6:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	jne .L_or_end_000b
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0080
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_0080
.L_if_else_0080:
	mov rax, L_constants + 2
.L_if_end_0080:
.L_or_end_000b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00b6:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	jne .L_or_end_000c
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0081
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1 ; push n (num of args)
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_0081
.L_if_else_0081:
	mov rax, L_constants + 2
.L_if_end_0081:
.L_or_end_000c:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00b5:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0019:	; new closure is in rax
	mov qword [free_var_31], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push qword 2 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00b7
	jmp .L_lambda_simple_end_00b7
.L_lambda_simple_code_00b7:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00b7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00b7:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing map1
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing map-list
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00b8
	jmp .L_lambda_simple_end_00b8
.L_lambda_simple_code_00b8:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00b8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00b8:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0082
	mov rax, L_constants + 1
	jmp .L_if_end_0082
.L_if_else_0082:
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, PARAM(0)	; param f
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_0082:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00b8:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param map1
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00b9
	jmp .L_lambda_simple_end_00b9
.L_lambda_simple_code_00b9:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00b9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00b9:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0083
	mov rax, L_constants + 1
	jmp .L_if_end_0083
.L_if_else_0083:
	mov rax, PARAM(0)	; param f
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_0083:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00b9:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param map-list
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_001a
	jmp .L_lambda_opt_end_001a
.L_lambda_opt_code_001a:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0084
	mov rax, L_constants + 1
	jmp .L_if_end_0084
.L_if_else_0084:
	mov rax, PARAM(0)	; param f
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_0084:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_001a:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00b7:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_97], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ba
	jmp .L_lambda_simple_end_00ba
.L_lambda_simple_code_00ba:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00ba
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ba:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00bb
	jmp .L_lambda_simple_end_00bb
.L_lambda_simple_code_00bb:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00bb
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00bb:
	enter 0, 0
	mov rax, PARAM(1)	; param a
	push rax
	mov rax, PARAM(0)	; param r
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00bb:	; new closure is in rax
	push rax
	mov rax, L_constants + 1
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 3 ; push n (num of args)
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00ba:	; new closure is in rax
	mov qword [free_var_112], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push qword 2 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00bc
	jmp .L_lambda_simple_end_00bc
.L_lambda_simple_code_00bc:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00bc
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00bc:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run-1
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing run-2
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00bd
	jmp .L_lambda_simple_end_00bd
.L_lambda_simple_code_00bd:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00bd
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00bd:
	enter 0, 0
	mov rax, PARAM(1)	; param sr
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0085
	mov rax, PARAM(0)	; param s1
	jmp .L_if_end_0085
.L_if_else_0085:
	mov rax, PARAM(0)	; param s1
	push rax
	mov rax, PARAM(1)	; param sr
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param sr
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_0085:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00bd:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run-1
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00be
	jmp .L_lambda_simple_end_00be
.L_lambda_simple_code_00be:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00be
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00be:
	enter 0, 0
	mov rax, PARAM(0)	; param s1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0086
	mov rax, PARAM(1)	; param s2
	jmp .L_if_end_0086
.L_if_else_0086:
	mov rax, PARAM(0)	; param s1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param s2
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_0086:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00be:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param run-2
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_001b
	jmp .L_lambda_opt_end_001b
.L_lambda_opt_code_001b:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0087
	mov rax, L_constants + 1
	jmp .L_if_end_0087
.L_if_else_0087:
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_0087:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_001b:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00bc:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_32], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00bf
	jmp .L_lambda_simple_end_00bf
.L_lambda_simple_code_00bf:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00bf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00bf:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00c0
	jmp .L_lambda_simple_end_00c0
.L_lambda_simple_code_00c0:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_00c0
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00c0:
	enter 0, 0
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_104]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0088
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_0088
.L_if_else_0088:
	mov rax, PARAM(0)	; param f
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_0088:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_00c0:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_001c
	jmp .L_lambda_opt_end_001c
.L_lambda_opt_code_001c:	
	mov r9, 2
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param f
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var ss
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_001c:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00bf:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_80], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00c1
	jmp .L_lambda_simple_end_00c1
.L_lambda_simple_code_00c1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00c1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00c1:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00c2
	jmp .L_lambda_simple_end_00c2
.L_lambda_simple_code_00c2:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_00c2
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00c2:
	enter 0, 0
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_104]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0089
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_0089
.L_if_else_0089:
	mov rax, PARAM(0)	; param f
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, L_constants + 1
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_32]	; free var append
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_0089:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_00c2:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_001d
	jmp .L_lambda_opt_end_001d
.L_lambda_opt_code_001d:	
	mov r9, 2
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param f
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var ss
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_001d:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00c1:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_81], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push qword 2 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00c3
	jmp .L_lambda_simple_end_00c3
.L_lambda_simple_code_00c3:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00c3
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00c3:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing bin+
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing error
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00c4
	jmp .L_lambda_simple_end_00c4
.L_lambda_simple_code_00c4:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_00c4
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00c4:
	enter 0, 0
	mov rax, L_constants + 2148
	push rax
	mov rax, L_constants + 2157
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_00c4:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param error
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00c5
	jmp .L_lambda_simple_end_00c5
.L_lambda_simple_code_00c5:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00c5
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00c5:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0095
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_008c
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_11]	; free var __bin-add-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_008c
.L_if_else_008c:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_008b
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_008b
.L_if_else_008b:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_008a
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_008a
.L_if_else_008a:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_008a:
.L_if_end_008b:
.L_if_end_008c:
	jmp .L_if_end_0095
.L_if_else_0095:
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0094
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_008f
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_28]	; free var __bin_integer_to_fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_008f
.L_if_else_008f:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_008e
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_008e
.L_if_else_008e:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_008d
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_008d
.L_if_else_008d:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_008d:
.L_if_end_008e:
.L_if_end_008f:
	jmp .L_if_end_0094
.L_if_else_0094:
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0093
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0092
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_0092
.L_if_else_0092:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0091
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_0091
.L_if_else_0091:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0090
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_0090
.L_if_else_0090:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_0090:
.L_if_end_0091:
.L_if_end_0092:
	jmp .L_if_end_0093
.L_if_else_0093:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_0093:
.L_if_end_0094:
.L_if_end_0095:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00c5:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param bin+
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_001e
	jmp .L_lambda_opt_end_001e
.L_lambda_opt_code_001e:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin+
	mov rax, qword [rax]
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 3 ; push n (num of args)
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_001e:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00c3:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_1], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push qword 2 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00c6
	jmp .L_lambda_simple_end_00c6
.L_lambda_simple_code_00c6:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00c6
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00c6:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing bin-
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing error
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00c7
	jmp .L_lambda_simple_end_00c7
.L_lambda_simple_code_00c7:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_00c7
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00c7:
	enter 0, 0
	mov rax, L_constants + 2251
	push rax
	mov rax, L_constants + 2157
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_00c7:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param error
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00c8
	jmp .L_lambda_simple_end_00c8
.L_lambda_simple_code_00c8:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00c8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00c8:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00a1
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0098
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_27]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_0098
.L_if_else_0098:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0097
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_0097
.L_if_else_0097:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_109]	; free var real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0096
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_0096
.L_if_else_0096:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_0096:
.L_if_end_0097:
.L_if_end_0098:
	jmp .L_if_end_00a1
.L_if_else_00a1:
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00a0
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_009b
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_009b
.L_if_else_009b:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_009a
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_009a
.L_if_else_009a:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_0099
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_0099
.L_if_else_0099:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_0099:
.L_if_end_009a:
.L_if_end_009b:
	jmp .L_if_end_00a0
.L_if_else_00a0:
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_009f
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_009e
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_009e
.L_if_else_009e:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_009d
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_009d
.L_if_else_009d:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_009c
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_009c
.L_if_else_009c:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_009c:
.L_if_end_009d:
.L_if_end_009e:
	jmp .L_if_end_009f
.L_if_else_009f:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_009f:
.L_if_end_00a0:
.L_if_end_00a1:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00c8:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param bin-
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_001f
	jmp .L_lambda_opt_end_001f
.L_lambda_opt_code_001f:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00a2
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00a2
.L_if_else_00a2:
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00c9
	jmp .L_lambda_simple_end_00c9
.L_lambda_simple_code_00c9:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00c9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00c9:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	mov rax, PARAM(0)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00c9:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00a2:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_001f:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00c6:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_2], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push qword 2 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ca
	jmp .L_lambda_simple_end_00ca
.L_lambda_simple_code_00ca:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00ca
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ca:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing bin*
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing error
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00cb
	jmp .L_lambda_simple_end_00cb
.L_lambda_simple_code_00cb:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_00cb
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00cb:
	enter 0, 0
	mov rax, L_constants + 2283
	push rax
	mov rax, L_constants + 2157
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_00cb:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param error
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00cc
	jmp .L_lambda_simple_end_00cc
.L_lambda_simple_code_00cc:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00cc
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00cc:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00ae
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00a5
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_24]	; free var __bin-mul-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00a5
.L_if_else_00a5:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00a4
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00a4
.L_if_else_00a4:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00a3
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00a3
.L_if_else_00a3:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00a3:
.L_if_end_00a4:
.L_if_end_00a5:
	jmp .L_if_end_00ae
.L_if_else_00ae:
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00ad
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00a8
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00a8
.L_if_else_00a8:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00a7
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00a7
.L_if_else_00a7:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00a6
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00a6
.L_if_else_00a6:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00a6:
.L_if_end_00a7:
.L_if_end_00a8:
	jmp .L_if_end_00ad
.L_if_else_00ad:
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00ac
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00ab
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00ab
.L_if_else_00ab:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00aa
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00aa
.L_if_else_00aa:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00a9
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00a9
.L_if_else_00a9:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00a9:
.L_if_end_00aa:
.L_if_end_00ab:
	jmp .L_if_end_00ac
.L_if_else_00ac:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00ac:
.L_if_end_00ad:
.L_if_end_00ae:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00cc:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param bin*
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0020
	jmp .L_lambda_opt_end_0020
.L_lambda_opt_code_0020:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin*
	mov rax, qword [rax]
	push rax
	mov rax, L_constants + 2292
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 3 ; push n (num of args)
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0020:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00ca:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_0], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push qword 2 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00cd
	jmp .L_lambda_simple_end_00cd
.L_lambda_simple_code_00cd:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00cd
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00cd:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing bin/
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing error
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ce
	jmp .L_lambda_simple_end_00ce
.L_lambda_simple_code_00ce:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_00ce
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ce:
	enter 0, 0
	mov rax, L_constants + 2311
	push rax
	mov rax, L_constants + 2157
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_00ce:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param error
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00cf
	jmp .L_lambda_simple_end_00cf
.L_lambda_simple_code_00cf:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00cf
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00cf:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00ba
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00b1
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_15]	; free var __bin-div-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00b1
.L_if_else_00b1:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00b0
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00b0
.L_if_else_00b0:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00af
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00af
.L_if_else_00af:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00af:
.L_if_end_00b0:
.L_if_end_00b1:
	jmp .L_if_end_00ba
.L_if_else_00ba:
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00b9
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00b4
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00b4
.L_if_else_00b4:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00b3
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00b3
.L_if_else_00b3:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00b2
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00b2
.L_if_else_00b2:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00b2:
.L_if_end_00b3:
.L_if_end_00b4:
	jmp .L_if_end_00b9
.L_if_else_00b9:
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00b8
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00b7
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00b7
.L_if_else_00b7:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00b6
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00b6
.L_if_else_00b6:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00b5
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00b5
.L_if_else_00b5:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00b5:
.L_if_end_00b6:
.L_if_end_00b7:
	jmp .L_if_end_00b8
.L_if_else_00b8:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var error
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00b8:
.L_if_end_00b9:
.L_if_end_00ba:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00cf:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param bin/
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0021
	jmp .L_lambda_opt_end_0021
.L_lambda_opt_code_0021:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00bb
	mov rax, L_constants + 2292
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00bb
.L_if_else_00bb:
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, L_constants + 2292
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00d0
	jmp .L_lambda_simple_end_00d0
.L_lambda_simple_code_00d0:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00d0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00d0:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	mov rax, PARAM(0)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00d0:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00bb:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0021:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00cd:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_3], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00d1
	jmp .L_lambda_simple_end_00d1
.L_lambda_simple_code_00d1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00d1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00d1:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00bc
	mov rax, L_constants + 2292
	jmp .L_if_end_00bc
.L_if_else_00bc:
	mov rax, PARAM(0)	; param n
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_79]	; free var fact
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00bc:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00d1:	; new closure is in rax
	mov qword [free_var_79], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_4], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_5], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_7], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_8], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_6], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push qword 7 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00d2
	jmp .L_lambda_simple_end_00d2
.L_lambda_simple_code_00d2:	
	cmp qword [rsp + 8 * 2], 7
	je .L_lambda_simple_arity_check_ok_00d2
	push qword [rsp + 8 * 2]
	push 7
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00d2:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing bin<=?
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing bin>?
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(2)	; boxing bin>=?
	mov qword [rax], rbx
	mov PARAM(2), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(3)	; boxing bin=?
	mov qword [rax], rbx
	mov PARAM(3), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(4)	; boxing bin<?
	mov qword [rax], rbx
	mov PARAM(4), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(6)	; boxing exit
	mov qword [rax], rbx
	mov PARAM(6), rax
	mov rax, sob_void

	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00d3
	jmp .L_lambda_simple_end_00d3
.L_lambda_simple_code_00d3:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_00d3
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00d3:
	enter 0, 0
	mov rax, L_constants + 2412
	push rax
	mov rax, L_constants + 2421
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_00d3:	; new closure is in rax
	push rax
	mov rax, PARAM(6)	; param exit
	pop qword [rax]
	mov rax, sob_void

	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00d4
	jmp .L_lambda_simple_end_00d4
.L_lambda_simple_code_00d4:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_00d4
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00d4:
	enter 0, 0
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00d5
	jmp .L_lambda_simple_end_00d5
.L_lambda_simple_code_00d5:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00d5
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00d5:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00c8
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00bf
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator-zz
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00bf
.L_if_else_00bf:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00be
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00be
.L_if_else_00be:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00bd
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00bd
.L_if_else_00bd:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 6]	; bound var exit
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00bd:
.L_if_end_00be:
.L_if_end_00bf:
	jmp .L_if_end_00c8
.L_if_else_00c8:
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00c7
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00c2
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00c2
.L_if_else_00c2:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00c1
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00c1
.L_if_else_00c1:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00c0
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00c0
.L_if_else_00c0:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 6]	; bound var exit
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00c0:
.L_if_end_00c1:
.L_if_end_00c2:
	jmp .L_if_end_00c7
.L_if_else_00c7:
	mov rax, PARAM(0)	; param a
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00c6
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00c5
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00c5
.L_if_else_00c5:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00c4
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00c4
.L_if_else_00c4:
	mov rax, PARAM(1)	; param b
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00c3
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00c3
.L_if_else_00c3:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 6]	; bound var exit
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00c3:
.L_if_end_00c4:
.L_if_end_00c5:
	jmp .L_if_end_00c6
.L_if_else_00c6:

	push 0 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 6]	; bound var exit
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 0 + 1)]
	mov rcx, [rbp + 8 * (3 + 0 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00c6:
.L_if_end_00c7:
.L_if_end_00c8:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00d5:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_00d4:	; new closure is in rax
	mov PARAM(5), rax	; param (set! make-bin-comparator ... )
	mov rax, sob_void

	mov rax, qword [free_var_21]	; free var __bin-less-than-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_19]	; free var __bin-less-than-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_20]	; free var __bin-less-than-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, PARAM(5)	; param make-bin-comparator
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(4)	; param bin<?
	pop qword [rax]
	mov rax, sob_void

	mov rax, qword [free_var_18]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_16]	; free var __bin-equal-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_17]	; free var __bin-equal-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, PARAM(5)	; param make-bin-comparator
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(3)	; param bin=?
	pop qword [rax]
	mov rax, sob_void

	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00d6
	jmp .L_lambda_simple_end_00d6
.L_lambda_simple_code_00d6:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00d6
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00d6:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 4]	; bound var bin<?
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_100]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00d6:	; new closure is in rax
	push rax
	mov rax, PARAM(2)	; param bin>=?
	pop qword [rax]
	mov rax, sob_void

	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00d7
	jmp .L_lambda_simple_end_00d7
.L_lambda_simple_code_00d7:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00d7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00d7:
	enter 0, 0
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 4]	; bound var bin<?
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00d7:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param bin>?
	pop qword [rax]
	mov rax, sob_void

	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00d8
	jmp .L_lambda_simple_end_00d8
.L_lambda_simple_code_00d8:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00d8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00d8:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var bin>?
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_100]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00d8:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param bin<=?
	pop qword [rax]
	mov rax, sob_void

	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00d9
	jmp .L_lambda_simple_end_00d9
.L_lambda_simple_code_00d9:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00d9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00d9:
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1 ; push n (num of args)
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00da
	jmp .L_lambda_simple_end_00da
.L_lambda_simple_code_00da:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00da
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00da:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00db
	jmp .L_lambda_simple_end_00db
.L_lambda_simple_code_00db:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00db
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00db:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	jne .L_or_end_000d
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-ordering
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00c9
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00c9
.L_if_else_00c9:
	mov rax, L_constants + 2
.L_if_end_00c9:
.L_or_end_000d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00db:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0022
	jmp .L_lambda_opt_end_0022
.L_lambda_opt_code_0022:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0022:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00da:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00d9:	; new closure is in rax
	push rax
	push 1 ; push n (num of args)
	mov r8, 7
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00dc
	jmp .L_lambda_simple_end_00dc
.L_lambda_simple_code_00dc:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00dc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00dc:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 4]	; bound var bin<?
	mov rax, qword [rax]
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_4], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin<=?
	mov rax, qword [rax]
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_5], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var bin>?
	mov rax, qword [rax]
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_7], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var bin>=?
	mov rax, qword [rax]
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_8], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 3]	; bound var bin=?
	mov rax, qword [rax]
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_6], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00dc:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(7)
.L_lambda_simple_end_00d2:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_69], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_68], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_70], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_72], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_71], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00dd
	jmp .L_lambda_simple_end_00dd
.L_lambda_simple_code_00dd:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00dd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00dd:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0023
	jmp .L_lambda_opt_end_0023
.L_lambda_opt_code_0023:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0023:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00dd:	; new closure is in rax
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00de
	jmp .L_lambda_simple_end_00de
.L_lambda_simple_code_00de:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00de
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00de:
	enter 0, 0
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_69], rax
	mov rax, sob_void

	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_68], rax
	mov rax, sob_void

	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_70], rax
	mov rax, sob_void

	mov rax, qword [free_var_7]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_72], rax
	mov rax, sob_void

	mov rax, qword [free_var_8]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_71], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00de:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_66], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_67], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00df
	jmp .L_lambda_simple_end_00df
.L_lambda_simple_code_00df:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00df
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00df:
	enter 0, 0
	mov rax, PARAM(0)	; param e
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	jne .L_or_end_000e
	mov rax, PARAM(0)	; param e
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00ca
	mov rax, PARAM(0)	; param e
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_90]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00ca
.L_if_else_00ca:
	mov rax, L_constants + 2
.L_if_end_00ca:
.L_or_end_000e:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00df:	; new closure is in rax
	mov qword [free_var_90], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, qword [free_var_95]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00e0
	jmp .L_lambda_simple_end_00e0
.L_lambda_simple_code_00e0:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00e0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e0:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0024
	jmp .L_lambda_opt_end_0024
.L_lambda_opt_code_0024:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var xs
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00cd
	mov rax, L_constants + 0
	jmp .L_if_end_00cd
.L_if_else_00cd:
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var xs
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00cb
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var xs
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	jmp .L_if_end_00cb
.L_if_else_00cb:
	mov rax, L_constants + 2
.L_if_end_00cb:
	cmp rax, sob_boolean_false
	je .L_if_else_00cc
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var xs
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	jmp .L_if_end_00cc
.L_if_else_00cc:
	mov rax, L_constants + 2582
	push rax
	mov rax, L_constants + 2591
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
.L_if_end_00cc:
.L_if_end_00cd:
	push rax
	push 1 ; push n (num of args)
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00e1
	jmp .L_lambda_simple_end_00e1
.L_lambda_simple_code_00e1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00e1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e1:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param x
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-vector
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00e1:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0024:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00e0:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_95], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, qword [free_var_93]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00e2
	jmp .L_lambda_simple_end_00e2
.L_lambda_simple_code_00e2:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00e2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e2:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0025
	jmp .L_lambda_opt_end_0025
.L_lambda_opt_code_0025:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var chs
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00d0
	mov rax, L_constants + 4
	jmp .L_if_end_00d0
.L_if_else_00d0:
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var chs
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00ce
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var chs
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	jmp .L_if_end_00ce
.L_if_else_00ce:
	mov rax, L_constants + 2
.L_if_end_00ce:
	cmp rax, sob_boolean_false
	je .L_if_else_00cf
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var chs
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	jmp .L_if_end_00cf
.L_if_else_00cf:
	mov rax, L_constants + 2643
	push rax
	mov rax, L_constants + 2652
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
.L_if_end_00cf:
.L_if_end_00d0:
	push rax
	push 1 ; push n (num of args)
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00e3
	jmp .L_lambda_simple_end_00e3
.L_lambda_simple_code_00e3:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00e3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e3:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-string
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00e3:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0025:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00e2:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_93], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00e4
	jmp .L_lambda_simple_end_00e4
.L_lambda_simple_code_00e4:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00e4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e4:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00e5
	jmp .L_lambda_simple_end_00e5
.L_lambda_simple_code_00e5:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00e5
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e5:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00d1
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, L_constants + 0
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_95]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00d1
.L_if_else_00d1:
	mov rax, PARAM(0)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00e6
	jmp .L_lambda_simple_end_00e6
.L_lambda_simple_code_00e6:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00e6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e6:
	enter 0, 0
	mov rax, PARAM(0)	; param v
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx

	mov rax, PARAM(0)	; param v
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00e6:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00d1:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00e5:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00e7
	jmp .L_lambda_simple_end_00e7
.L_lambda_simple_code_00e7:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00e7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e7:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2232
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00e7:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00e4:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_89], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00e8
	jmp .L_lambda_simple_end_00e8
.L_lambda_simple_code_00e8:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00e8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e8:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00e9
	jmp .L_lambda_simple_end_00e9
.L_lambda_simple_code_00e9:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00e9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00e9:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00d2
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, L_constants + 4
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_93]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00d2
.L_if_else_00d2:
	mov rax, PARAM(0)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ea
	jmp .L_lambda_simple_end_00ea
.L_lambda_simple_code_00ea:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00ea
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ea:
	enter 0, 0
	mov rax, PARAM(0)	; param str
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx

	mov rax, PARAM(0)	; param str
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00ea:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00d2:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00e9:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00eb
	jmp .L_lambda_simple_end_00eb
.L_lambda_simple_code_00eb:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00eb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00eb:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2232
	push rax
	push 2 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00eb:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00e8:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_88], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0026
	jmp .L_lambda_opt_end_0026
.L_lambda_opt_code_0026:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_89]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0026:	; new closure is in rax
	mov qword [free_var_123], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ec
	jmp .L_lambda_simple_end_00ec
.L_lambda_simple_code_00ec:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00ec
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ec:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ed
	jmp .L_lambda_simple_end_00ed
.L_lambda_simple_code_00ed:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_00ed
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ed:
	enter 0, 0
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00d3
	mov rax, PARAM(0)	; param str
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_116]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00d3
.L_if_else_00d3:
	mov rax, L_constants + 1
.L_if_end_00d3:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_00ed:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ee
	jmp .L_lambda_simple_end_00ee
.L_lambda_simple_code_00ee:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00ee
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ee:
	enter 0, 0
	mov rax, PARAM(0)	; param str
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00ee:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00ec:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_113], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ef
	jmp .L_lambda_simple_end_00ef
.L_lambda_simple_code_00ef:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00ef
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ef:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00f0
	jmp .L_lambda_simple_end_00f0
.L_lambda_simple_code_00f0:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_00f0
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00f0:
	enter 0, 0
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00d4
	mov rax, PARAM(0)	; param v
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_127]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00d4
.L_if_else_00d4:
	mov rax, L_constants + 1
.L_if_end_00d4:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_00f0:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00f1
	jmp .L_lambda_simple_end_00f1
.L_lambda_simple_code_00f1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00f1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00f1:
	enter 0, 0
	mov rax, PARAM(0)	; param v
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00f1:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00ef:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_124], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00f2
	jmp .L_lambda_simple_end_00f2
.L_lambda_simple_code_00f2:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00f2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00f2:
	enter 0, 0

	push qword 0 ; Push n (num of args)
	mov rax, qword [free_var_122]	; free var trng
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_111]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00f2:	; new closure is in rax
	mov qword [free_var_107], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00f3
	jmp .L_lambda_simple_end_00f3
.L_lambda_simple_code_00f3:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00f3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00f3:
	enter 0, 0
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param x
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00f3:	; new closure is in rax
	mov qword [free_var_106], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00f4
	jmp .L_lambda_simple_end_00f4
.L_lambda_simple_code_00f4:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00f4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00f4:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, L_constants + 2232
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00f4:	; new closure is in rax
	mov qword [free_var_98], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00f5
	jmp .L_lambda_simple_end_00f5
.L_lambda_simple_code_00f5:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00f5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00f5:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	mov rax, L_constants + 2868
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_111]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00f5:	; new closure is in rax
	mov qword [free_var_78], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00f6
	jmp .L_lambda_simple_end_00f6
.L_lambda_simple_code_00f6:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00f6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00f6:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_78]	; free var even?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_100]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00f6:	; new closure is in rax
	mov qword [free_var_103], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00f7
	jmp .L_lambda_simple_end_00f7
.L_lambda_simple_code_00f7:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00f7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00f7:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_98]	; free var negative?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00d5
	mov rax, PARAM(0)	; param x
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00d5
.L_if_else_00d5:
	mov rax, PARAM(0)	; param x
.L_if_end_00d5:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00f7:	; new closure is in rax
	mov qword [free_var_30], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00f8
	jmp .L_lambda_simple_end_00f8
.L_lambda_simple_code_00f8:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00f8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00f8:
	enter 0, 0
	mov rax, PARAM(0)	; param e1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00d6
	mov rax, PARAM(1)	; param e2
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	jmp .L_if_end_00d6
.L_if_else_00d6:
	mov rax, L_constants + 2
.L_if_end_00d6:
	cmp rax, sob_boolean_false
	je .L_if_else_00e2
	mov rax, PARAM(0)	; param e1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param e2
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_76]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00d7
	mov rax, PARAM(0)	; param e1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param e2
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_76]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00d7
.L_if_else_00d7:
	mov rax, L_constants + 2
.L_if_end_00d7:
	jmp .L_if_end_00e2
.L_if_else_00e2:
	mov rax, PARAM(0)	; param e1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_131]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00d9
	mov rax, PARAM(1)	; param e2
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_131]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00d8
	mov rax, PARAM(0)	; param e1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param e2
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	jmp .L_if_end_00d8
.L_if_else_00d8:
	mov rax, L_constants + 2
.L_if_end_00d8:
	jmp .L_if_end_00d9
.L_if_else_00d9:
	mov rax, L_constants + 2
.L_if_end_00d9:
	cmp rax, sob_boolean_false
	je .L_if_else_00e1
	mov rax, PARAM(0)	; param e1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_124]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param e2
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_124]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_76]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00e1
.L_if_else_00e1:
	mov rax, PARAM(0)	; param e1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_121]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00db
	mov rax, PARAM(1)	; param e2
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_121]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00da
	mov rax, PARAM(0)	; param e1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(1)	; param e2
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	jmp .L_if_end_00da
.L_if_else_00da:
	mov rax, L_constants + 2
.L_if_end_00da:
	jmp .L_if_end_00db
.L_if_else_00db:
	mov rax, L_constants + 2
.L_if_end_00db:
	cmp rax, sob_boolean_false
	je .L_if_else_00e0
	mov rax, PARAM(0)	; param e1
	push rax
	mov rax, PARAM(1)	; param e2
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_120]	; free var string=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00e0
.L_if_else_00e0:
	mov rax, PARAM(0)	; param e1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_102]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00dc
	mov rax, PARAM(1)	; param e2
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_102]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	jmp .L_if_end_00dc
.L_if_else_00dc:
	mov rax, L_constants + 2
.L_if_end_00dc:
	cmp rax, sob_boolean_false
	je .L_if_else_00df
	mov rax, PARAM(0)	; param e1
	push rax
	mov rax, PARAM(1)	; param e2
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00df
.L_if_else_00df:
	mov rax, PARAM(0)	; param e1
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_73]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00dd
	mov rax, PARAM(1)	; param e2
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_73]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	jmp .L_if_end_00dd
.L_if_else_00dd:
	mov rax, L_constants + 2
.L_if_end_00dd:
	cmp rax, sob_boolean_false
	je .L_if_else_00de
	mov rax, PARAM(0)	; param e1
	push rax
	mov rax, PARAM(1)	; param e2
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_70]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00de
.L_if_else_00de:
	mov rax, PARAM(0)	; param e1
	push rax
	mov rax, PARAM(1)	; param e2
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_75]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00de:
.L_if_end_00df:
.L_if_end_00e0:
.L_if_end_00e1:
.L_if_end_00e2:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00f8:	; new closure is in rax
	mov qword [free_var_76], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00f9
	jmp .L_lambda_simple_end_00f9
.L_lambda_simple_code_00f9:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00f9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00f9:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00e4
	mov rax, L_constants + 2
	jmp .L_if_end_00e4
.L_if_else_00e4:
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_75]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00e3
	mov rax, PARAM(1)	; param s
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00e3
.L_if_else_00e3:
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_34]	; free var assoc
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00e3:
.L_if_end_00e4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00f9:	; new closure is in rax
	mov qword [free_var_34], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push qword 2 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00fa
	jmp .L_lambda_simple_end_00fa
.L_lambda_simple_code_00fa:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00fa
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00fa:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing add
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00fb
	jmp .L_lambda_simple_end_00fb
.L_lambda_simple_code_00fb:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_00fb
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00fb:
	enter 0, 0
	mov rax, PARAM(2)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00e5
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_00e5
.L_if_else_00e5:
	mov rax, PARAM(0)	; param target
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(2)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(2)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 5 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00fc
	jmp .L_lambda_simple_end_00fc
.L_lambda_simple_code_00fc:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_00fc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00fc:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_00fc:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00e5:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_00fb:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00fd
	jmp .L_lambda_simple_end_00fd
.L_lambda_simple_code_00fd:	
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_00fd
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00fd:
	enter 0, 0
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(4)	; param limit
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00e6
	mov rax, PARAM(0)	; param target
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_116]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx

	mov rax, PARAM(0)	; param target
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(4)	; param limit
	push rax
	push 5 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 5 + 1)]
	mov rcx, [rbp + 8 * (3 + 5 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00e6
.L_if_else_00e6:
	mov rax, PARAM(1)	; param i
.L_if_end_00e6:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_00fd:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0027
	jmp .L_lambda_opt_end_0027
.L_lambda_opt_code_0027:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var strings
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_93]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var strings
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0027:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00fa:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_114], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push qword 2 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00fe
	jmp .L_lambda_simple_end_00fe
.L_lambda_simple_code_00fe:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_00fe
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00fe:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing add
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_00ff
	jmp .L_lambda_simple_end_00ff
.L_lambda_simple_code_00ff:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_00ff
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_00ff:
	enter 0, 0
	mov rax, PARAM(2)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00e7
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_00e7
.L_if_else_00e7:
	mov rax, PARAM(0)	; param target
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(2)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(2)	; param s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 5 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0100
	jmp .L_lambda_simple_end_0100
.L_lambda_simple_code_0100:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0100
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0100:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0100:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00e7:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_00ff:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0101
	jmp .L_lambda_simple_end_0101
.L_lambda_simple_code_0101:	
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0101
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0101:
	enter 0, 0
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(4)	; param limit
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00e8
	mov rax, PARAM(0)	; param target
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_127]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx

	mov rax, PARAM(0)	; param target
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(4)	; param limit
	push rax
	push 5 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 5 + 1)]
	mov rcx, [rbp + 8 * (3 + 5 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00e8
.L_if_else_00e8:
	mov rax, PARAM(1)	; param i
.L_if_end_00e8:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0101:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_0028
	jmp .L_lambda_opt_end_0028
.L_lambda_opt_code_0028:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var vectors
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_95]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var vectors
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0028:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_00fe:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_125], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0102
	jmp .L_lambda_simple_end_0102
.L_lambda_simple_code_0102:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0102
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0102:
	enter 0, 0
	mov rax, PARAM(0)	; param str
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_113]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_112]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_88]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0102:	; new closure is in rax
	mov qword [free_var_117], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0103
	jmp .L_lambda_simple_end_0103
.L_lambda_simple_code_0103:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0103
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0103:
	enter 0, 0
	mov rax, PARAM(0)	; param vec
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_124]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_112]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_89]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0103:	; new closure is in rax
	mov qword [free_var_128], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0104
	jmp .L_lambda_simple_end_0104
.L_lambda_simple_code_0104:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0104
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0104:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0105
	jmp .L_lambda_simple_end_0105
.L_lambda_simple_code_0105:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0105
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0105:
	enter 0, 0
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(2)	; param j
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00e9
	mov rax, PARAM(0)	; param str
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_116]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0106
	jmp .L_lambda_simple_end_0106
.L_lambda_simple_code_0106:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0106
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0106:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_116]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0106:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00e9
.L_if_else_00e9:
	mov rax, PARAM(0)	; param str
.L_if_end_00e9:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0105:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0107
	jmp .L_lambda_simple_end_0107
.L_lambda_simple_code_0107:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0107
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0107:
	enter 0, 0
	mov rax, PARAM(0)	; param str
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0108
	jmp .L_lambda_simple_end_0108
.L_lambda_simple_code_0108:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0108
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0108:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00ea
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	jmp .L_if_end_00ea
.L_if_else_00ea:
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00ea:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0108:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0107:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0104:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_118], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push qword 1 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0109
	jmp .L_lambda_simple_end_0109
.L_lambda_simple_code_0109:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0109
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0109:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_010a
	jmp .L_lambda_simple_end_010a
.L_lambda_simple_code_010a:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_010a
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_010a:
	enter 0, 0
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(2)	; param j
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00eb
	mov rax, PARAM(0)	; param vec
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_127]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_010b
	jmp .L_lambda_simple_end_010b
.L_lambda_simple_code_010b:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_010b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_010b:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_127]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_010b:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00eb
.L_if_else_00eb:
	mov rax, PARAM(0)	; param vec
.L_if_end_00eb:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_010a:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_010c
	jmp .L_lambda_simple_end_010c
.L_lambda_simple_code_010c:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_010c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_010c:
	enter 0, 0
	mov rax, PARAM(0)	; param vec
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_010d
	jmp .L_lambda_simple_end_010d
.L_lambda_simple_code_010d:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_010d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_010d:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00ec
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	jmp .L_if_end_00ec
.L_if_else_00ec:
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	mov rax, L_constants + 2232
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 3 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 3 + 1)]
	mov rcx, [rbp + 8 * (3 + 3 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00ec:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_010d:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_010c:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0109:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	mov qword [free_var_129], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_010e
	jmp .L_lambda_simple_end_010e
.L_lambda_simple_code_010e:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_010e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_010e:
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1 ; push n (num of args)
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_010f
	jmp .L_lambda_simple_end_010f
.L_lambda_simple_code_010f:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_010f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_010f:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0110
	jmp .L_lambda_simple_end_0110
.L_lambda_simple_code_0110:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0110
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0110:
	enter 0, 0
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00ed
	mov rax, PARAM(0)	; param i
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var generator
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00ed
.L_if_else_00ed:
	mov rax, L_constants + 1
.L_if_end_00ed:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0110:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rax, L_constants + 2232
	push rax
	push 1 ; push n (num of args)
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_010f:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_010e:	; new closure is in rax
	mov qword [free_var_92], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0111
	jmp .L_lambda_simple_end_0111
.L_lambda_simple_code_0111:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0111
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0111:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_93]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0112
	jmp .L_lambda_simple_end_0112
.L_lambda_simple_code_0112:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0112
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0112:
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1 ; push n (num of args)
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0113
	jmp .L_lambda_simple_end_0113
.L_lambda_simple_code_0113:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0113
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0113:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0114
	jmp .L_lambda_simple_end_0114
.L_lambda_simple_code_0114:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0114
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0114:
	enter 0, 0
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00ee
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var generator
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx

	mov rax, PARAM(0)	; param i
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00ee
.L_if_else_00ee:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
.L_if_end_00ee:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0114:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rax, L_constants + 2232
	push rax
	push 1 ; push n (num of args)
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0113:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0112:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0111:	; new closure is in rax
	mov qword [free_var_94], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0115
	jmp .L_lambda_simple_end_0115
.L_lambda_simple_code_0115:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0115
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0115:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_95]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0116
	jmp .L_lambda_simple_end_0116
.L_lambda_simple_code_0116:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0116
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0116:
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1 ; push n (num of args)
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0117
	jmp .L_lambda_simple_end_0117
.L_lambda_simple_code_0117:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0117
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0117:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0118
	jmp .L_lambda_simple_end_0118
.L_lambda_simple_code_0118:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0118
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0118:
	enter 0, 0
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00ef
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var generator
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx

	mov rax, PARAM(0)	; param i
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 1 ; push n (num of args)
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00ef
.L_if_else_00ef:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
.L_if_end_00ef:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0118:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rax, L_constants + 2232
	push rax
	push 1 ; push n (num of args)
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0117:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0116:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0115:	; new closure is in rax
	mov qword [free_var_96], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0119
	jmp .L_lambda_simple_end_0119
.L_lambda_simple_code_0119:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0119
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0119:
	enter 0, 0
	mov rax, PARAM(2)	; param n
	push rax
	push qword 1 ; Push n (num of args)
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00f2
	mov rax, L_constants + 3192
	jmp .L_if_end_00f2
.L_if_else_00f2:
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00f1
	mov rax, L_constants + 3192
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_3]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_91]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	jmp .L_if_end_00f1
.L_if_else_00f1:
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	cmp rax, sob_boolean_false
	je .L_if_else_00f0
	mov rax, L_constants + 3192
	jmp .L_if_end_00f0
.L_if_else_00f0:
	mov rax, L_constants + 3192
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, L_constants + 2292
	push rax
	push qword 2 ; Push n (num of args)
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push qword 3 ; Push n (num of args)
	mov rax, qword [free_var_91]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
	push rax
	push 2 ; push n (num of args)
	mov rax, qword [free_var_3]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
.L_if_end_00f0:
.L_if_end_00f1:
.L_if_end_00f2:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0119:	; new closure is in rax
	mov qword [free_var_91], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_011a
	jmp .L_lambda_simple_end_011a
.L_lambda_simple_code_011a:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_011a
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_011a:
	enter 0, 0
	mov rax, L_constants + 3217
	push rax
	push 1 ; push n (num of args)
	mov rax, qword [free_var_134]	; free var write-char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 1 + 1)]
	mov rcx, [rbp + 8 * (3 + 1 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_011a:	; new closure is in rax
	mov qword [free_var_99], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_011b
	jmp .L_lambda_simple_end_011b
.L_lambda_simple_code_011b:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_011b
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_011b:
	enter 0, 0
	mov rax, L_constants + 0
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_011b:	; new closure is in rax
	mov qword [free_var_132], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, L_constants + 2868
	push rax
	mov rax, L_constants + 3232
	push rax
	push qword 3 ; Push n (num of args)
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_011c
	jmp .L_lambda_simple_end_011c
.L_lambda_simple_code_011c:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_011c
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_011c:
	enter 0, 0
	mov rax, PARAM(2)	; param y
	push rax
	mov rax, PARAM(1)	; param x
	push rax
	push 2 ; push n (num of args)
	mov rax, PARAM(0)	; param funky
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	push qword [rbp + 8 * 1]
	mov rbp, [rbp + 8 * (3 + 2 + 1)]
	mov rcx, [rbp + 8 * (3 + 2 + 2)]
	mov [rbp + 8*1], rcx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	jmp rbx
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_011c:	; new closure is in rax
	cmp byte [rax], T_closure ; check if proc is a closure
	jne L_error_non_closure
	mov rbx, [rax+1] ; rbx <-- rax.env
	push qword rbx
	mov rbx, [rax + 1 + 4] ; rbx <-- rax.code
	call rbx
Lend:
	mov rdi, rax
	call print_sexpr_if_not_void

        mov rdi, fmt_memory_usage
        mov rsi, qword [top_of_memory]
        sub rsi, memory
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, 0
        call exit

L_error_fvar_undefined:
        push rax
        mov rdi, qword [stderr]  ; destination
        mov rsi, fmt_undefined_free_var_1
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        pop rax
        mov rax, qword [rax + 1] ; string
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rsi, 1               ; sizeof(char)
        mov rdx, qword [rax + 1] ; string-length
        mov rcx, qword [stderr]  ; destination
        mov rax, 0
        ENTER
        call fwrite
        LEAVE
        mov rdi, [stderr]       ; destination
        mov rsi, fmt_undefined_free_var_2
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -10
        call exit

L_error_non_closure:
        mov rdi, qword [stderr]
        mov rsi, fmt_non_closure
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -2
        call exit

L_error_improper_list:
	mov rdi, qword [stderr]
	mov rsi, fmt_error_improper_list
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
	mov rax, -7
	call exit

L_error_incorrect_arity_simple:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_simple
        jmp L_error_incorrect_arity_common
L_error_incorrect_arity_opt:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_opt
L_error_incorrect_arity_common:
        pop rdx
        pop rcx
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -6
        call exit

section .data
fmt_undefined_free_var_1:
        db `!!! The free variable \0`
fmt_undefined_free_var_2:
        db ` was used before it was defined.\n\0`
fmt_incorrect_arity_simple:
        db `!!! Expected %ld arguments, but given %ld\n\0`
fmt_incorrect_arity_opt:
        db `!!! Expected at least %ld arguments, but given %ld\n\0`
fmt_memory_usage:
        db `\n!!! Used %ld bytes of dynamically-allocated memory\n\n\0`
fmt_non_closure:
        db `!!! Attempting to apply a non-closure!\n\0`
fmt_error_improper_list:
	db `!!! The argument is not a proper list!\n\0`

section .bss
memory:
	resb gbytes(1)

section .data
top_of_memory:
        dq memory

section .text
malloc:
        mov rax, qword [top_of_memory]
        add qword [top_of_memory], rdi
        ret

L_code_ptr_return:
	cmp qword [rsp + 8*2], 2
	jne L_error_arg_count_2
	mov rcx, qword [rsp + 8*3]
	assert_integer(rcx)
	mov rcx, qword [rcx + 1]
	cmp rcx, 0
	jl L_error_integer_range
	mov rax, qword [rsp + 8*4]
.L0:
        cmp rcx, 0
        je .L1
	mov rbp, qword [rbp]
	dec rcx
	jg .L0
.L1:
	mov rsp, rbp
	pop rbp
        pop rbx
        mov rcx, qword [rsp + 8*1]
        lea rsp, [rsp + 8*rcx + 8*2]
	jmp rbx

;;; r8 : params
;;; r9 : | env |
extend_lexical_environment:
;;; fill in for final project
        ret

;;; fixing the stack
;;; R9 : List.length params'
opt_fix_stack:
        mov rcx, qword [rsp + 8*3] 	; count
        cmp rcx, r9
        jl L_error_arg_count_2
        jg .Lmore
        mov rsi, rsp
        sub rsp, 8*1
        mov rdi, rsp
        add rcx, 4
        cld
        rep movsq
        inc qword [rsp + 8*3] 		; ++count
        mov qword [rsp + 8*r9 + 8*4], sob_nil
        jmp .Ldone
.Lmore:
        mov rbx, [rsp + 8*3] 		; how many were pushed
        lea r11, [rsp + 8*rbx + 8*3] 	; ptr to top element in the frame
        mov r10, sob_nil     		; initial argl
        mov r12, r11			; backup ptr to top element
        sub rcx, r9			; size of list
.L0:
        cmp rcx, 0
        je .L0out
        mov rdi, 1 + 8 + 8 		; sizeof(pair)
        call malloc
        mov byte [rax], T_pair 		; rtti
        mov qword [rax + 1 + 8], r10 	; cdr
        mov rbx, qword [r11]
        mov qword [rax + 1], rbx 	; car
        mov r10, rax
        sub r11, 8*1
        dec rcx
        jmp .L0
.L0out:
        mov qword [r12], r10 		; set list
        lea rdi, [r12 - 8*1]
        lea rsi, [rsp + 8*r9 + 8*3]
        mov rcx, r9
        add rcx, 4
        std
        rep movsq
        cld
        lea rsp, [rdi + 8*1]
        lea rbx, [r9 + 1]
        mov qword [rsp + 8*3], rbx
.Ldone:
        ret

L_code_ptr_make_list:
	enter 0, 0
        cmp COUNT, 1
        je .L0
        cmp COUNT, 2
        je .L1
        jmp L_error_arg_count_12
.L0:
        mov r9, sob_void
        jmp .L2
.L1:
        mov r9, PARAM(1)
.L2:
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_arg_negative
        mov r8, sob_nil
.L3:
        cmp rcx, 0
        jle .L4
        mov rdi, 1 + 8 + 8
        call malloc
        mov byte [rax], T_pair
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        mov r8, rax
        dec rcx
        jmp .L3
.L4:
        mov rax, r8
        cmp COUNT, 2
        je .L5
        leave
        ret AND_KILL_FRAME(1)
.L5:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_is_primitive:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rax, PARAM(0)
	assert_closure(rax)
	cmp SOB_CLOSURE_ENV(rax), 0
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_end
.L_false:
	mov rax, sob_boolean_false
.L_end:
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_length:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rbx, PARAM(0)
	mov rdi, 0
.L:
	cmp byte [rbx], T_nil
	je .L_end
	assert_pair(rbx)
	mov rbx, SOB_PAIR_CDR(rbx)
	inc rdi
	jmp .L
.L_end:
	call make_integer
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_break:
        cmp qword [rsp + 8 * 2], 0
        jne L_error_arg_count_0
        int3
        mov rax, sob_void
        ret AND_KILL_FRAME(0)        

L_code_ptr_frame:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0

        mov rdi, fmt_frame
        mov rsi, qword [rbp]    ; old rbp
        mov rdx, qword [rsi + 8*1] ; ret addr
        mov rcx, qword [rsi + 8*2] ; lexical environment
        mov r8, qword [rsi + 8*3] ; count
        lea r9, [rsi + 8*4]       ; address of argument 0
        push 0
        push r9
        push r8                   ; we'll use it when printing the params
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

.L:
        mov rcx, qword [rsp]
        cmp rcx, 0
        je .L_out
        mov rdi, fmt_frame_param_prefix
        mov rsi, qword [rsp + 8*2]
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

        mov rcx, qword [rsp]
        dec rcx
        mov qword [rsp], rcx    ; dec arg count
        inc qword [rsp + 8*2]   ; increment index of current arg
        mov rdi, qword [rsp + 8*1] ; addr of addr current arg
        lea r9, [rdi + 8]          ; addr of next arg
        mov qword [rsp + 8*1], r9  ; backup addr of next arg
        mov rdi, qword [rdi]       ; addr of current arg
        call print_sexpr
        mov rdi, fmt_newline
        mov rax, 0
        ENTER
        call printf
        LEAVE
        jmp .L
.L_out:
        mov rdi, fmt_frame_continue
        mov rax, 0
        ENTER
        call printf
        call getchar
        LEAVE
        
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(0)
        
print_sexpr_if_not_void:
	cmp rdi, sob_void
	je .done
	call print_sexpr
	mov rdi, fmt_newline
	mov rax, 0
	ENTER
	call printf
	LEAVE
.done:
	ret

section .data
fmt_frame:
        db `RBP = %p; ret addr = %p; lex env = %p; param count = %d\n\0`
fmt_frame_param_prefix:
        db `==[param %d]==> \0`
fmt_frame_continue:
        db `Hit <Enter> to continue...\0`
fmt_newline:
	db `\n\0`
fmt_void:
	db `#<void>\0`
fmt_nil:
	db `()\0`
fmt_boolean_false:
	db `#f\0`
fmt_boolean_true:
	db `#t\0`
fmt_char_backslash:
	db `#\\\\\0`
fmt_char_dquote:
	db `#\\"\0`
fmt_char_simple:
	db `#\\%c\0`
fmt_char_null:
	db `#\\nul\0`
fmt_char_bell:
	db `#\\bell\0`
fmt_char_backspace:
	db `#\\backspace\0`
fmt_char_tab:
	db `#\\tab\0`
fmt_char_newline:
	db `#\\newline\0`
fmt_char_formfeed:
	db `#\\page\0`
fmt_char_return:
	db `#\\return\0`
fmt_char_escape:
	db `#\\esc\0`
fmt_char_space:
	db `#\\space\0`
fmt_char_hex:
	db `#\\x%02X\0`
fmt_gensym:
        db `G%ld\0`
fmt_closure:
	db `#<closure at 0x%08X env=0x%08X code=0x%08X>\0`
fmt_lparen:
	db `(\0`
fmt_dotted_pair:
	db ` . \0`
fmt_rparen:
	db `)\0`
fmt_space:
	db ` \0`
fmt_empty_vector:
	db `#()\0`
fmt_vector:
	db `#(\0`
fmt_real:
	db `%f\0`
fmt_fraction:
	db `%ld/%ld\0`
fmt_zero:
	db `0\0`
fmt_int:
	db `%ld\0`
fmt_unknown_scheme_object_error:
	db `\n\n!!! Error: Unknown Scheme-object (RTTI 0x%02X) `
	db `at address 0x%08X\n\n\0`
fmt_dquote:
	db `\"\0`
fmt_string_char:
        db `%c\0`
fmt_string_char_7:
        db `\\a\0`
fmt_string_char_8:
        db `\\b\0`
fmt_string_char_9:
        db `\\t\0`
fmt_string_char_10:
        db `\\n\0`
fmt_string_char_11:
        db `\\v\0`
fmt_string_char_12:
        db `\\f\0`
fmt_string_char_13:
        db `\\r\0`
fmt_string_char_34:
        db `\\"\0`
fmt_string_char_92:
        db `\\\\\0`
fmt_string_char_hex:
        db `\\x%X;\0`

section .text

print_sexpr:
	enter 0, 0
	mov al, byte [rdi]
	cmp al, T_void
	je .Lvoid
	cmp al, T_nil
	je .Lnil
	cmp al, T_boolean_false
	je .Lboolean_false
	cmp al, T_boolean_true
	je .Lboolean_true
	cmp al, T_char
	je .Lchar
	cmp al, T_interned_symbol
	je .Linterned_symbol
        cmp al, T_uninterned_symbol
        je .Luninterned_symbol
	cmp al, T_pair
	je .Lpair
	cmp al, T_vector
	je .Lvector
	cmp al, T_closure
	je .Lclosure
	cmp al, T_real
	je .Lreal
	cmp al, T_fraction
	je .Lfraction
	cmp al, T_integer
	je .Linteger
	cmp al, T_string
	je .Lstring

	jmp .Lunknown_sexpr_type

.Lvoid:
	mov rdi, fmt_void
	jmp .Lemit

.Lnil:
	mov rdi, fmt_nil
	jmp .Lemit

.Lboolean_false:
	mov rdi, fmt_boolean_false
	jmp .Lemit

.Lboolean_true:
	mov rdi, fmt_boolean_true
	jmp .Lemit

.Lchar:
	mov al, byte [rdi + 1]
	cmp al, ' '
	jle .Lchar_whitespace
	cmp al, 92 		; backslash
	je .Lchar_backslash
	cmp al, '"'
	je .Lchar_dquote
	and rax, 255
	mov rdi, fmt_char_simple
	mov rsi, rax
	jmp .Lemit

.Lchar_whitespace:
	cmp al, 0
	je .Lchar_null
	cmp al, 7
	je .Lchar_bell
	cmp al, 8
	je .Lchar_backspace
	cmp al, 9
	je .Lchar_tab
	cmp al, 10
	je .Lchar_newline
	cmp al, 12
	je .Lchar_formfeed
	cmp al, 13
	je .Lchar_return
	cmp al, 27
	je .Lchar_escape
	and rax, 255
	cmp al, ' '
	je .Lchar_space
	mov rdi, fmt_char_hex
	mov rsi, rax
	jmp .Lemit	

.Lchar_backslash:
	mov rdi, fmt_char_backslash
	jmp .Lemit

.Lchar_dquote:
	mov rdi, fmt_char_dquote
	jmp .Lemit

.Lchar_null:
	mov rdi, fmt_char_null
	jmp .Lemit

.Lchar_bell:
	mov rdi, fmt_char_bell
	jmp .Lemit

.Lchar_backspace:
	mov rdi, fmt_char_backspace
	jmp .Lemit

.Lchar_tab:
	mov rdi, fmt_char_tab
	jmp .Lemit

.Lchar_newline:
	mov rdi, fmt_char_newline
	jmp .Lemit

.Lchar_formfeed:
	mov rdi, fmt_char_formfeed
	jmp .Lemit

.Lchar_return:
	mov rdi, fmt_char_return
	jmp .Lemit

.Lchar_escape:
	mov rdi, fmt_char_escape
	jmp .Lemit

.Lchar_space:
	mov rdi, fmt_char_space
	jmp .Lemit

.Lclosure:
	mov rsi, qword rdi
	mov rdi, fmt_closure
	mov rdx, SOB_CLOSURE_ENV(rsi)
	mov rcx, SOB_CLOSURE_CODE(rsi)
	jmp .Lemit

.Linterned_symbol:
	mov rdi, qword [rdi + 1] ; sob_string
	mov rsi, 1		 ; size = 1 byte
	mov rdx, qword [rdi + 1] ; length
	lea rdi, [rdi + 1 + 8]	 ; actual characters
	mov rcx, qword [stdout]	 ; FILE *
	ENTER
	call fwrite
	LEAVE
	jmp .Lend

.Luninterned_symbol:
        mov rsi, qword [rdi + 1] ; gensym counter
        mov rdi, fmt_gensym
        jmp .Lemit
	
.Lpair:
	push rdi
	mov rdi, fmt_lparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp] 	; pair
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi 		; pair
	mov rdi, SOB_PAIR_CDR(rdi)
.Lcdr:
	mov al, byte [rdi]
	cmp al, T_nil
	je .Lcdr_nil
	cmp al, T_pair
	je .Lcdr_pair
	push rdi
	mov rdi, fmt_dotted_pair
	mov rax, 0
        ENTER
	call printf
        LEAVE
	pop rdi
	call print_sexpr
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_nil:
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_pair:
	push rdi
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi
	mov rdi, SOB_PAIR_CDR(rdi)
	jmp .Lcdr

.Lvector:
	mov rax, qword [rdi + 1] ; length
	cmp rax, 0
	je .Lvector_empty
	push rdi
	mov rdi, fmt_vector
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	push qword [rdi + 1]
	push 1
	mov rdi, qword [rdi + 1 + 8] ; v[0]
	call print_sexpr
.Lvector_loop:
	; [rsp] index
	; [rsp + 8*1] limit
	; [rsp + 8*2] vector
	mov rax, qword [rsp]
	cmp rax, qword [rsp + 8*1]
	je .Lvector_end
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rax, qword [rsp]
	mov rbx, qword [rsp + 8*2]
	mov rdi, qword [rbx + 1 + 8 + 8 * rax] ; v[i]
	call print_sexpr
	inc qword [rsp]
	jmp .Lvector_loop

.Lvector_end:
	add rsp, 8*3
	mov rdi, fmt_rparen
	jmp .Lemit	

.Lvector_empty:
	mov rdi, fmt_empty_vector
	jmp .Lemit

.Lreal:
	push qword [rdi + 1]
	movsd xmm0, qword [rsp]
	add rsp, 8*1
	mov rdi, fmt_real
	mov rax, 1
	ENTER
	call printf
	LEAVE
	jmp .Lend

.Lfraction:
	mov rsi, qword [rdi + 1]
	mov rdx, qword [rdi + 1 + 8]
	cmp rsi, 0
	je .Lrat_zero
	cmp rdx, 1
	je .Lrat_int
	mov rdi, fmt_fraction
	jmp .Lemit

.Lrat_zero:
	mov rdi, fmt_zero
	jmp .Lemit

.Lrat_int:
	mov rdi, fmt_int
	jmp .Lemit

.Linteger:
	mov rsi, qword [rdi + 1]
	mov rdi, fmt_int
	jmp .Lemit

.Lstring:
	lea rax, [rdi + 1 + 8]
	push rax
	push qword [rdi + 1]
	mov rdi, fmt_dquote
	mov rax, 0
	ENTER
	call printf
	LEAVE
.Lstring_loop:
	; qword [rsp]: limit
	; qword [rsp + 8*1]: char *
	cmp qword [rsp], 0
	je .Lstring_end
	mov rax, qword [rsp + 8*1]
	mov al, byte [rax]
	and rax, 255
	cmp al, 7
        je .Lstring_char_7
        cmp al, 8
        je .Lstring_char_8
        cmp al, 9
        je .Lstring_char_9
        cmp al, 10
        je .Lstring_char_10
        cmp al, 11
        je .Lstring_char_11
        cmp al, 12
        je .Lstring_char_12
        cmp al, 13
        je .Lstring_char_13
        cmp al, 34
        je .Lstring_char_34
        cmp al, 92              ; \
        je .Lstring_char_92
        cmp al, ' '
        jl .Lstring_char_hex
        mov rdi, fmt_string_char
        mov rsi, rax
.Lstring_char_emit:
        mov rax, 0
        ENTER
        call printf
        LEAVE
        dec qword [rsp]
        inc qword [rsp + 8*1]
        jmp .Lstring_loop

.Lstring_char_7:
        mov rdi, fmt_string_char_7
        jmp .Lstring_char_emit

.Lstring_char_8:
        mov rdi, fmt_string_char_8
        jmp .Lstring_char_emit
        
.Lstring_char_9:
        mov rdi, fmt_string_char_9
        jmp .Lstring_char_emit

.Lstring_char_10:
        mov rdi, fmt_string_char_10
        jmp .Lstring_char_emit

.Lstring_char_11:
        mov rdi, fmt_string_char_11
        jmp .Lstring_char_emit

.Lstring_char_12:
        mov rdi, fmt_string_char_12
        jmp .Lstring_char_emit

.Lstring_char_13:
        mov rdi, fmt_string_char_13
        jmp .Lstring_char_emit

.Lstring_char_34:
        mov rdi, fmt_string_char_34
        jmp .Lstring_char_emit

.Lstring_char_92:
        mov rdi, fmt_string_char_92
        jmp .Lstring_char_emit

.Lstring_char_hex:
        mov rdi, fmt_string_char_hex
        mov rsi, rax
        jmp .Lstring_char_emit        

.Lstring_end:
	add rsp, 8 * 2
	mov rdi, fmt_dquote
	jmp .Lemit

.Lunknown_sexpr_type:
	mov rsi, fmt_unknown_scheme_object_error
	and rax, 255
	mov rdx, rax
	mov rcx, rdi
	mov rdi, qword [stderr]
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
        leave
        ret

.Lemit:
	mov rax, 0
        ENTER
	call printf
        LEAVE
	jmp .Lend

.Lend:
	LEAVE
	ret

;;; rdi: address of free variable
;;; rsi: address of code-pointer
bind_primitive:
        enter 0, 0
        push rdi
        mov rdi, (1 + 8 + 8)
        call malloc
        pop rdi
        mov byte [rax], T_closure
        mov SOB_CLOSURE_ENV(rax), 0 ; dummy, lexical environment
        mov SOB_CLOSURE_CODE(rax), rsi ; code pointer
        mov qword [rdi], rax
        mov rax, sob_void
        leave
        ret

L_code_ptr_ash:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_integer(rdi)
        mov rcx, PARAM(1)
        assert_integer(rcx)
        mov rdi, qword [rdi + 1]
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl .L_negative
.L_loop_positive:
        cmp rcx, 0
        je .L_exit
        sal rdi, cl
        shr rcx, 8
        jmp .L_loop_positive
.L_negative:
        neg rcx
.L_loop_negative:
        cmp rcx, 0
        je .L_exit
        sar rdi, cl
        shr rcx, 8
        jmp .L_loop_negative
.L_exit:
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logand:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        and rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        or rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logxor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        xor rdi, qword [r9 + 1]
        call make_integer
        LEAVE
        ret AND_KILL_FRAME(2)

L_code_ptr_lognot:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, qword [r8 + 1]
        not rdi
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_bin_apply:
;;; fill in for final project
	ret

L_code_ptr_is_null:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_nil
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_pair:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_pair
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_void:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_void
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_char
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_string:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_string
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        and byte [r8], T_symbol
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_uninterned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        cmp byte [r8], T_uninterned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_interned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_interned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_gensym:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        inc qword [gensym_count]
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_uninterned_symbol
        mov rcx, qword [gensym_count]
        mov qword [rax + 1], rcx
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_vector:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_vector
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_closure:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_closure
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_real
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_fraction
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_boolean
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_boolean_false:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_false
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean_true:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_true
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_number:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_number
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_collection:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_collection
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_cons:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_pair
        mov rbx, PARAM(0)
        mov SOB_PAIR_CAR(rax), rbx
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_display_sexpr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rdi, PARAM(0)
        call print_sexpr
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_write_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, SOB_CHAR_VALUE(rax)
        and rax, 255
        mov rdi, fmt_char
        mov rsi, rax
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_car:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CAR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_cdr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CDR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_string_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_string(rax)
        mov rdi, SOB_STRING_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_vector_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_vector(rax)
        mov rdi, SOB_VECTOR_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_real_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rbx, PARAM(0)
        assert_real(rbx)
        movsd xmm0, qword [rbx + 1]
        cvttsd2si rdi, xmm0
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_exit:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        mov rax, 0
        call exit

L_code_ptr_integer_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_fraction_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        push qword [rax + 1 + 8]
        cvtsi2sd xmm1, qword [rsp]
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_char_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, byte [rax + 1]
        and rax, 255
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, (1 + 8 + 8)
        call malloc
        mov rbx, qword [r8 + 1]
        mov byte [rax], T_fraction
        mov qword [rax + 1], rbx
        mov qword [rax + 1 + 8], 1
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        mov rbx, qword [rax + 1]
        cmp rbx, 0
        jle L_error_integer_range
        cmp rbx, 256
        jge L_error_integer_range
        mov rdi, (1 + 1)
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_trng:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        rdrand rdi
        shr rdi, 1
        call make_integer
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_zero:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        je .L_integer
        cmp byte [rax], T_fraction
        je .L_fraction
        cmp byte [rax], T_real
        je .L_real
        jmp L_error_incorrect_type
.L_integer:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_fraction:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_real:
        pxor xmm0, xmm0
        push qword [rax + 1]
        movsd xmm1, qword [rsp]
        ucomisd xmm0, xmm1
        je .L_zero
.L_not_zero:
        mov rax, sob_boolean_false
        jmp .L_end
.L_zero:
        mov rax, sob_boolean_true
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_raw_bin_add_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        addsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        subsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        mulsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        pxor xmm2, xmm2
        ucomisd xmm1, xmm2
        je L_error_division_by_zero
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	add rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        add rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	sub rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        sub rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	cqo
	mov rax, qword [r8 + 1]
	mul qword [r9 + 1]
	mov rdi, rax
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_bin_div_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r9 + 1]
	cmp rdi, 0
	je L_error_division_by_zero
	mov rsi, qword [r8 + 1]
	call normalize_fraction
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        cmp qword [r9 + 1], 0
        je L_error_division_by_zero
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
normalize_fraction:
        push rsi
        push rdi
        call gcd
        mov rbx, rax
        pop rax
        cqo
        idiv rbx
        mov r8, rax
        pop rax
        cqo
        idiv rbx
        mov r9, rax
        cmp r9, 0
        je .L_zero
        cmp r8, 1
        je .L_int
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_fraction
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        ret
.L_zero:
        mov rdi, 0
        call make_integer
        ret
.L_int:
        mov rdi, r9
        call make_integer
        ret

iabs:
        mov rax, rdi
        cmp rax, 0
        jl .Lneg
        ret
.Lneg:
        neg rax
        ret

gcd:
        call iabs
        mov rbx, rax
        mov rdi, rsi
        call iabs
        cmp rax, 0
        jne .L0
        xchg rax, rbx
.L0:
        cmp rbx, 0
        je .L1
        cqo
        div rbx
        mov rax, rdx
        xchg rax, rbx
        jmp .L0
.L1:
        ret

L_code_ptr_error:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_interned_symbol(rsi)
        mov rsi, PARAM(1)
        assert_string(rsi)
        mov rdi, fmt_scheme_error_part_1
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rdi, PARAM(0)
        call print_sexpr
        mov rdi, fmt_scheme_error_part_2
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, PARAM(1)       ; sob_string
        mov rsi, 1              ; size = 1 byte
        mov rdx, qword [rax + 1] ; length
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rcx, qword [stdout]  ; FILE*
	ENTER
        call fwrite
	LEAVE
        mov rdi, fmt_scheme_error_part_3
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, -9
        call exit

L_code_ptr_raw_less_than_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jae .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_less_than_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jge .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_less_than_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rsi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jge .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_equal_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rdi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_quotient:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_remainder:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rdx
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_car:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CAR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_cdr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_string_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov bl, byte [rdi + 1 + 8 + 1 * rcx]
        mov rdi, 2
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, [rdi + 1 + 8 + 8 * rcx]
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        mov qword [rdi + 1 + 8 + 8 * rcx], rax
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_string_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        assert_char(rax)
        mov al, byte [rax + 1]
        mov byte [rdi + 1 + 8 + 1 * rcx], al
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_make_vector:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        lea rdi, [1 + 8 + 8 * rcx]
        call malloc
        mov byte [rax], T_vector
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov qword [rax + 1 + 8 + 8 * r8], rdx
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_make_string:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        assert_char(rdx)
        mov dl, byte [rdx + 1]
        lea rdi, [1 + 8 + 1 * rcx]
        call malloc
        mov byte [rax], T_string
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov byte [rax + 1 + 8 + 1 * r8], dl
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_numerator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_denominator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1 + 8]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_eq:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov rdi, PARAM(0)
	mov rsi, PARAM(1)
	cmp rdi, rsi
	je .L_eq_true
	mov dl, byte [rdi]
	cmp dl, byte [rsi]
	jne .L_eq_false
	cmp dl, T_char
	je .L_char
	cmp dl, T_interned_symbol
	je .L_interned_symbol
        cmp dl, T_uninterned_symbol
        je .L_uninterned_symbol
	cmp dl, T_real
	je .L_real
	cmp dl, T_fraction
	je .L_fraction
        cmp dl, T_integer
        je .L_integer
	jmp .L_eq_false
.L_integer:
        mov rax, qword [rsi + 1]
        cmp rax, qword [rdi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_fraction:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
	jne .L_eq_false
	mov rax, qword [rsi + 1 + 8]
	cmp rax, qword [rdi + 1 + 8]
	jne .L_eq_false
	jmp .L_eq_true
.L_real:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_interned_symbol:
	; never reached, because interned_symbols are static!
	; but I'm keeping it in case, I'll ever change
	; the implementation
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_uninterned_symbol:
        mov r8, qword [rdi + 1]
        cmp r8, qword [rsi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_char:
	mov bl, byte [rsi + 1]
	cmp bl, byte [rdi + 1]
	jne .L_eq_false
.L_eq_true:
	mov rax, sob_boolean_true
	jmp .L_eq_exit
.L_eq_false:
	mov rax, sob_boolean_false
.L_eq_exit:
	leave
	ret AND_KILL_FRAME(2)

make_real:
        enter 0, 0
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_real
        movsd qword [rax + 1], xmm0
        leave 
        ret
        
make_integer:
        enter 0, 0
        mov rsi, rdi
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_integer
        mov qword [rax + 1], rsi
        leave
        ret
        
L_error_integer_range:
        mov rdi, qword [stderr]
        mov rsi, fmt_integer_range
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -5
        call exit

L_error_arg_negative:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_negative
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_0:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_0
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_1:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_1
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_2:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_2
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_12:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_12
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_3:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_3
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit
        
L_error_incorrect_type:
        mov rdi, qword [stderr]
        mov rsi, fmt_type
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -4
        call exit

L_error_division_by_zero:
        mov rdi, qword [stderr]
        mov rsi, fmt_division_by_zero
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -8
        call exit

section .data
gensym_count:
        dq 0
fmt_char:
        db `%c\0`
fmt_arg_negative:
        db `!!! The argument cannot be negative.\n\0`
fmt_arg_count_0:
        db `!!! Expecting zero arguments. Found %d\n\0`
fmt_arg_count_1:
        db `!!! Expecting one argument. Found %d\n\0`
fmt_arg_count_12:
        db `!!! Expecting one required and one optional argument. Found %d\n\0`
fmt_arg_count_2:
        db `!!! Expecting two arguments. Found %d\n\0`
fmt_arg_count_3:
        db `!!! Expecting three arguments. Found %d\n\0`
fmt_type:
        db `!!! Function passed incorrect type\n\0`
fmt_integer_range:
        db `!!! Incorrect integer range\n\0`
fmt_division_by_zero:
        db `!!! Division by zero\n\0`
fmt_scheme_error_part_1:
        db `\n!!! The procedure \0`
fmt_scheme_error_part_2:
        db ` asked to terminate the program\n`
        db `    with the following message:\n\n\0`
fmt_scheme_error_part_3:
        db `\n\nGoodbye!\n\n\0`

section .note.GNU-stack
        
