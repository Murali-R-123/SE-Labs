
import pytest

from parking_fee import parking_fee, find_slot, monthly_pass


# ==========================================
# PARKING FEE TEST CASES
# ==========================================

def test_unknown_vehicle():
    with pytest.raises(ValueError, match="unknown vehicle"):
        parking_fee("bus", 60, False, False)


def test_negative_duration():
    with pytest.raises(ValueError, match="invalid duration"):
        parking_fee("car", -10, False, False)


def test_free_short_stay():
    assert parking_fee("car", 20, False, False) == 0


def test_hourly_fee_with_remainder():
    assert parking_fee("car", 90, False, False) == 60


def test_ev_discount():
    assert parking_fee("car", 120, True, False) == 30


def test_lost_ticket_charge():
    assert parking_fee("bike", 30, False, True) == 200


# ==========================================
# PARKING SLOT TEST CASES
# ==========================================

def test_parking_full():
    assert find_slot("car", 0, False) == "full"


def test_disabled_parking():
    assert find_slot("car", 5, True) == "ground floor"


def test_truck_parking():
    assert find_slot("truck", 5, False) == "basement"


def test_any_floor():
    assert find_slot("car", 5, False) == "any floor"


# ==========================================
# MONTHLY PASS TEST CASES
# ==========================================

def test_bike_monthly_pass():
    assert monthly_pass("bike", False) == 500


def test_car_monthly_pass_resident():
    assert monthly_pass("car", True) == 1200


def test_invalid_monthly_pass():
    with pytest.raises(ValueError, match="no pass for this vehicle"):
        monthly_pass("truck", False)
