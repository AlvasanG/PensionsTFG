from datetime import datetime, timedelta
from brownie import exceptions
from scripts.deploy_contract import deploy_pension
from scripts.helpful_scripts import get_account
import pytest


def test_create_pensioner():
    pension = deploy_pension()
    account = get_account()
    retireAt = int((datetime.now() + timedelta(seconds=1)).timestamp())
    benefitWindow = int((datetime.now() + timedelta(days=365)).timestamp())
    pension.createPensioner(retireAt, benefitWindow, {"from": account})
    assert pension.pensionerList(0) == account


def test_create_past_pensioner():
    pension = deploy_pension()
    account = get_account()
    retireAt = int((datetime.now() + timedelta(seconds=-1)).timestamp())
    benefitWindow = int((datetime.now() + timedelta(days=365)).timestamp())
    with pytest.raises(exceptions.VirtualMachineError):
        pension.createPensioner(retireAt, benefitWindow, {"from": account})


def test_create_existing_pensioner():
    pension = deploy_pension()
    account = get_account()
    retireAt = int((datetime.now() + timedelta(seconds=1)).timestamp())
    benefitWindow = int((datetime.now() + timedelta(days=365)).timestamp())
    pension.createPensioner(retireAt, benefitWindow, {"from": account})
    assert pension.pensionerList(0) == account
    with pytest.raises(exceptions.VirtualMachineError):
        pension.createPensioner(retireAt, benefitWindow, {"from": account})


def test_retire_existing_pensioner():
    pension = deploy_pension()
    account = get_account()
    retireAt = int((datetime.now() + timedelta(days=1)).timestamp())
    benefitWindow = int((datetime.now() + timedelta(days=365)).timestamp())
    pension.createPensioner(retireAt, benefitWindow, {"from": account})
    pension.setRetirementTimeNow({"from": account})
    with pytest.raises(exceptions.VirtualMachineError):
        pension.fundPension({"from": account, "value": 1})


def test_retire_non_existing_pensioner():
    pension = deploy_pension()
    account = get_account()
    with pytest.raises(exceptions.VirtualMachineError):
        pension.setRetirementTimeNow({"from": account})


def test_fund_pension():
    pension = deploy_pension()
    account = get_account()
    retireAt = int((datetime.now() + timedelta(days=1)).timestamp())
    benefitWindow = int((datetime.now() + timedelta(days=365)).timestamp())
    pension.createPensioner(retireAt, benefitWindow, {"from": account})
    pension.fundPension({"from": account, "value": 1})
    assert pension.balance() == 1


def test_non_existing_pensioner_fund():
    pension = deploy_pension()
    with pytest.raises(exceptions.VirtualMachineError):
        pension.fundPension({"from": get_account(), "value": 1})


def test_retired_pensioner_fund():
    pension = deploy_pension()
    account = get_account()
    retireAt = int((datetime.now() + timedelta(days=1)).timestamp())
    benefitWindow = int((datetime.now() + timedelta(days=365)).timestamp())
    pension.createPensioner(retireAt, benefitWindow, {"from": account})
    pension.setRetirementTimeNow({"from": account})
    with pytest.raises(exceptions.VirtualMachineError):
        pension.fundPension({"from": account, "value": 1})


def test_fund_zero():
    pension = deploy_pension()
    account = get_account()
    retireAt = int((datetime.now() + timedelta(days=1)).timestamp())
    benefitWindow = int((datetime.now() + timedelta(days=365)).timestamp())
    pension.createPensioner(retireAt, benefitWindow, {"from": account})
    pension.fundPension({"from": account, "value": 0})
    assert pension.balance() == 0
