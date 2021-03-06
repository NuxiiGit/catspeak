/* Catspeak Tests
 * --------------
 * Kat @katsaii
 */

function __catspeak_ext_tests_assert_eq(_expects, _got) {
    var callstack_pos = argument_count > 2 ? argument[2] : 1;
    var pass;
    if (is_array(_expects) && is_array(_got)) {
        pass = array_equals(_expects, _got);
    } else {
        pass = _expects == _got;
    }
    if not (pass) {
        var msg = "expected '" + string(_expects) + "' (" + typeof(_expects) +
                ") got '" + string(_got) + "' (" + typeof(_got) + ")";
        var callstack = debug_get_callstack();
        show_error("failed unit test at " + callstack[callstack_pos] + " -- " + msg, false);
    }
}

function __catspeak_ext_tests_assert_true(_condition) {
    __catspeak_ext_tests_assert_eq(true, _condition, 2);
}

function __catspeak_ext_tests_assert_false(_condition) {
    __catspeak_ext_tests_assert_eq(false, _condition, 2);
}

try {
    // basic functionality
    var session = catspeak_session_create();
    catspeak_session_set_source(session, "return 12");
    var result = catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);
    __catspeak_ext_tests_assert_eq(12, result);

    // empty source code
    var session = catspeak_session_create();
    catspeak_session_set_source(session, "");
    catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);

    // whitespace
    var session = catspeak_session_create();
    catspeak_session_set_source(session, "\n\n\t \r\n\n");
    catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);

    // comments
    var session = catspeak_session_create();
    catspeak_session_set_source(session, @'
        -- hello
        --another comment
    ');
    catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);

    // implicit return
    var session = catspeak_session_create();
    catspeak_session_enable_implicit_return(session, true);
    catspeak_session_set_source(session, "18");
    var result = catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);
    __catspeak_ext_tests_assert_eq(18, result);

    // shared workspace
    var session = catspeak_session_create();
    catspeak_session_enable_shared_workspace(session, true);
    catspeak_session_set_source(session, "a = 3");
    catspeak_session_create_process_eager(session);
    catspeak_session_set_source(session, "return a");
    var result = catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);
    __catspeak_ext_tests_assert_eq(3, result);

    // global variables
    var session = catspeak_session_create();
    catspeak_session_enable_global_access(session, true);
    catspeak_session_add_constant(session, "global", global);
    catspeak_session_set_source(session, @'
        global.result = "secret message"
    ');
    catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);
    __catspeak_ext_tests_assert_eq("secret message", global.result);

    // ans variable
    var session = catspeak_session_create();
    catspeak_session_enable_implicit_return(session, true);
    catspeak_session_set_source(session, @'
        "hello world"
        return ans
    ');
    var result = catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);
    __catspeak_ext_tests_assert_eq("hello world", result);

    // assignment statements
    var session = catspeak_session_create();
    catspeak_session_enable_implicit_return(session, true);
    catspeak_session_set_source(session, @'
        var = 3
        var2 = var
        return [var, var2]
    ');
    var result = catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);
    __catspeak_ext_tests_assert_eq([3, 3], result);

    // foreign functions and values
    var session = catspeak_session_create();
    catspeak_session_add_constant(session, "const", -12);
    catspeak_session_add_function(session, "funct", max);
    catspeak_session_set_source(session, "return [const, funct]");
    var result = catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);
    __catspeak_ext_tests_assert_eq(-12, result[0]);
    __catspeak_ext_tests_assert_eq(max, method_get_index(result[1]));

    // gml interface
    var session = catspeak_session_create();
    catspeak_ext_session_add_gml_maths(session);
    catspeak_session_set_source(session, @'
        a = -3
        b = 12
        c = a * b + -a
        d = max a b c
        return [a, b, c, d]
    ');
    var result = catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);
    __catspeak_ext_tests_assert_eq([-3, 12, -33, 12], result);

    // groupings
    var session = catspeak_session_create();
    catspeak_session_set_source(session, @'
        a = (1 + (1 + 1))
        b = : 1 + : 1 + 1
        return [a, b]
    ');
    var result = catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);
    __catspeak_ext_tests_assert_eq([3, 3], result);

    // data types
    var session = catspeak_session_create();
    catspeak_session_set_source(session, @'
        return {
            .int 1
            .float 1.5
            .nan NaN
            .array [
                "hello world"
                true
                false
            ]
            .object {
                .x undefined
                .y infinity
            }
        }
    ');
    var result = catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);
    __catspeak_ext_tests_assert_eq(1, result[$ "int"]);
    __catspeak_ext_tests_assert_eq(1.5, result[$ "float"]);
    __catspeak_ext_tests_assert_true(is_nan(result[$ "nan"]));
    __catspeak_ext_tests_assert_eq(["hello world", true, false], result[$ "array"]);
    __catspeak_ext_tests_assert_eq(undefined, result[$ "object"][$ "x"]);
    __catspeak_ext_tests_assert_eq(infinity, result[$ "object"][$ "y"]);

    // if statements
    var session = catspeak_session_create();
    catspeak_session_set_source(session, @'
        a = 3
        b = 5
        if (a > b) {
            c = "greater"
        } else if (a < b) {
            c = "less"
        } else {
            c = "equal"
        }
        return c
    ');
    var result = catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);
    __catspeak_ext_tests_assert_eq("less", result);

    // while loops
    var session = catspeak_session_create();
    var counter = { n : 0 };
    catspeak_session_add_function(session, "register_count", method(counter, function() {
        n += 1;
    }));
    catspeak_session_set_source(session, @'
        count = 0
        limit = 10
        while (count < limit) {
            run register_count
            count = count + 1
        }
        return count
    ');
    var result = catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);
    __catspeak_ext_tests_assert_eq(counter.n, result);

    // break points
    var session = catspeak_session_create();
    catspeak_session_add_function(session, "failure", function(_number) {
        show_error("failed to break out of loop " + string(_number), true);
    });
    catspeak_session_set_source(session, @'
        while true {
            break
            failure 1
        }
        while true {
            while true {
                break 2
                failure 2
            }
            failure 3
        }
    ');
    catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);

    // continue points
    var session = catspeak_session_create();
    catspeak_session_add_function(session, "failure", function(_number) {
        throw "failed to continue outside of loop " + string(_number);
    });
    catspeak_session_set_source(session, @'
        count = 10
        while (count > 0) {
            count = count - 1
            while true {
                continue 2
                failure 1
            }
        }
    ');
    catspeak_session_create_process_eager(session);
    catspeak_session_destroy(session);

    // JSON-like syntax
    var json_obj = catspeak_ext_json_parse(@'
    {
        "Arrs": [1, 2, 3],
        "Objs": {
            "x": "hello",
            "y": "world"
        },
        "Lits": [null, true, false]
    }
    ');
    var catspeak_obj = catspeak_ext_json_parse(@'
    {
        .Arrs [1, 2, 3]
        .Objs {
            .x "hello"
            .y "world"
        }
        .Lits [null, true, false]
    }
    ');
    __catspeak_ext_tests_assert_eq(catspeak_obj[$ "Arrs"], json_obj[$ "Arrs"]);
    __catspeak_ext_tests_assert_eq(catspeak_obj[$ "Objs"][$ "x"], json_obj[$ "Objs"][$ "x"]);
    __catspeak_ext_tests_assert_eq(catspeak_obj[$ "Objs"][$ "y"], json_obj[$ "Objs"][$ "y"]);
    __catspeak_ext_tests_assert_eq(catspeak_obj[$ "Lits"], json_obj[$ "Lits"]);

    // success
    show_debug_message("ALL CATSPEAK TESTS PASSED SUCCESSFULLY");
} catch (_e) {
    var msg = is_struct(_e) && variable_struct_exists(_e, "message") ? _e[$ "message"] : string(_e);
    show_debug_message("AN ERROR OCCURRED WHEN RUNNING CATSPEAK UNIT TESTS:\n" + msg);
}