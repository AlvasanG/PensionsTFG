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


def createPensioner(indexAccount, extraSeconds=1, benefitWindow=1):
    account = get_account(indexAccount)
    pension = PensionSystem[-1]
    # today = int((datetime.now() + timedelta(days=7300)).timestamp())
    today = int((datetime.now() + timedelta(seconds=extraSeconds)).timestamp())
    starting_tx = pension.createPensioner(today, benefitWindow, {"from": account})
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


def createMultipleAccounts():
    createPensioner(0, 100000000, 100000000)
    createPensioner(1, 100000000, 100000000)
    createPensioner(2, 100000000, 100000000)


def fundMultiple():
    fundPension(0, 5 * 10 ** 18)
    print(f"\nPAGAMOS PARA LA PENSION {PensionSystem[-1].balance()}\n")

    fundPension(1, 1 * 10 ** 18)
    print(f"\nPAGAMOS PARA LA PENSION {PensionSystem[-1].balance()}\n")

    fundPension(2, 1 * 10 ** 18)
    print(f"\nPAGAMOS PARA LA PENSION {PensionSystem[-1].balance()}\n")

    fundPension(0, 1 * 10 ** 18)
    print(f"\nPAGAMOS PARA LA PENSION {PensionSystem[-1].balance()}\n")


def main():
    deploy_pension()
    createPensioner(1, 100000000, 100000000)
    createPensioner(2, 100000000, 100000000)
