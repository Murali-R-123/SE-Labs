
import pytest
from parking_fee import parking_fee, find_slot, monthly_pass


# parking_fee() tests

def test_invalid_vehicle_branch():
    with pytest.raises(ValueError):
        parking_fee("bus", 60, False, False)


def test_valid_vehicle_branch():
    assert parking_fee("bike", 60, False, False) == 10


def test_negative_duration_branch():
    with pytest.raises(ValueError):
        parking_fee("car", -1, False, False)


def test_valid_duration_branch():
    assert parking_fee("car", 60, False, False) == 30


def test_free_parking_branch():
    assert parking_fee("car", 30, False, False) == 0


def test_paid_parking_branch():
    assert parking_fee("car", 60, False, False) == 30


def test_exact_hour_branch():
    assert parking_fee("car", 120, False, False) == 60


def test_partial_hour_branch():
    assert parking_fee("car", 61, False, False) == 60


def test_ev_discount_branch():
    assert parking_fee("car", 60, True, False) == 15


def test_ev_truck_no_discount_branch():
    assert parking_fee("truck", 60, True, False) == 60


def test_non_ev_branch():
    assert parking_fee("car", 60, False, False) == 30


def test_lost_ticket_branch():
    assert parking_fee("bike", 60, False, True) == 210


def test_normal_ticket_branch():
    assert parking_fee("bike", 60, False, False) == 10


# find_slot() tests

def test_no_free_slots_branch():
    assert find_slot("car", 0, False) == "full"


def test_available_slots_branch():
    assert find_slot("car", 5, False) == "any floor"


def test_disabled_slot_branch():
    assert find_slot("car", 5, True) == "ground floor"


def test_non_disabled_slot_branch():
    assert find_slot("car", 5, False) == "any floor"


def test_truck_slot_branch():
    assert find_slot("truck", 5, False) == "basement"


def test_non_truck_slot_branch():
    assert find_slot("bike", 5, False) == "any floor"


# monthly_pass() tests

def test_bike_pass_branch():
    assert monthly_pass("bike", False) == 500


def test_car_pass_branch():
    assert monthly_pass("car", False) == 1500


def test_invalid_pass_branch():
    with pytest.raises(ValueError):
        monthly_pass("truck", False)


def test_resident_discount_branch():
    assert monthly_pass("car", True) == 1200


def test_non_resident_branch():
    assert monthly_pass("car", False) == 1500


def test_bike_resident_discount():
    assert monthly_pass("bike", True) == 400
