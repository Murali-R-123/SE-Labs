
from hypothesis import given, strategies as st
from parking_fee import minutes_parked, hourly_rate, format_plate


# Test 1: minutes_parked should not crash
@given(st.text() | st.none())
def test_minutes_parked_no_crash(s):
    try:
        minutes_parked(s)
    except Exception as e:
        assert False, f"minutes_parked crashed with input {s!r}: {e}"


# Test 2: hourly_rate should not crash
@given(st.text() | st.none())
def test_hourly_rate_no_crash(s):
    try:
        hourly_rate(s)
    except Exception as e:
        assert False, f"hourly_rate crashed with input {s!r}: {e}"


# Test 3: format_plate should not crash
@given(st.text() | st.none())
def test_format_plate_no_crash(s):
    try:
        format_plate(s)
    except Exception as e:
        assert False, f"format_plate crashed with input {s!r}: {e}"
