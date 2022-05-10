from tracemalloc import start
from turtle import pensize
from venv import create
from scripts.helpful_scripts import get_account
from brownie import PensionSystem, SavingsAccount, network
import time
from datetime import datetime, timedelta

# SAVINGS ACCOUNT #
def deploy_savings():
    account = get_account()
    savings = SavingsAccount.deploy({"from": account})
    print("Deployed savings account")
    print(savings)
    return savings


# PENSION SYSTEM #
def deploy_pension():
    account = get_account()
    pension = PensionSystem.deploy({"from": account})
    return pension


def createPensioner(indexAccount, extraSeconds=1):
    account = get_account(indexAccount)
    pension = PensionSystem[-1]
    # today = int((datetime.now() + timedelta(days=7300)).timestamp())
    today = int((datetime.now() + timedelta(seconds=extraSeconds)).timestamp())
    starting_tx = pension.createPensioner(today, {"from": account})
    starting_tx.wait(1)


def fundPension(indexAccount, value):
    account = get_account(indexAccount)
    pension = PensionSystem[-1]
    starting_tx = pension.fundPension({"from": account, "value": value})
    starting_tx.wait(1)


def retirePensioner(indexAccount):
    account = get_account(indexAccount)
    pension = PensionSystem[-1]
    starting_tx = pension.retirePensioner({"from": account})
    starting_tx.wait(1)


def calculateState():
    account = get_account()
    pension = PensionSystem[-1]
    starting_tx = pension.calculateState({"from": account})
    print(starting_tx)
    starting_tx.wait(1)
