from threading import activeCount
from brownie import *
from web3 import Web3
import json
import time
import random


def zero_gas_fees():
    def zero_price(web3, transaction_params):
        return 0
    w3 = Web3()
    w3.eth.set_gas_price_strategy(zero_price)
    return w3


def generate_user_accounts():
    for _ in range(30):
        accounts.add()


def airdrop_test(gov_token):
    for i in range(30):
        gov_token.airDropTokens({"from": accounts[i]})
    print("Early Adopter Balance: " +
          str(gov_token.balanceOf(accounts[0], {"from": accounts[0]})))
    print("Adopter Balance: " +
          str(gov_token.balanceOf(accounts[20], {"from": accounts[0]})))


def run_election(rep_dao, gov_token):
    """
    Simulate election with top 11 governors as winners, also ensure that payouts
    are done correctly
    """
    tx_rept = rep_dao.startElection.transact({"from": accounts[0]})
    gov_election = GovernorVoting.at(str(tx_rept.new_contracts[0]))
    for i in range(20):  # Register all voters
        gov_election.register({"from": accounts[i]})

    for i in range(11):  # Nominate 11 candidates
        gov_election.nominate(accounts[i], {"from": accounts[i]})

    for i in range(20):
        gov_token.approve(gov_election.address, 10**10, {"from": accounts[i]})
        candidate = random.randint(0, 10)
        vote = random.randint(
            0, int(gov_token.balanceOf(accounts[i], {"from": accounts[i]})))
        gov_election.vote(accounts[candidate], vote, {"from": accounts[i]})

    tx_rept = rep_dao.endElection.transact({"from": accounts[0]})
    tx_rept.wait(1)

    return tx_rept


def governor_proposal_sim(gov_proposal, rep_dao):
    """
    Run four proposals and pass two, simulate voting
    """
    one_cnt = gov_proposal.createProposal.transact(
        "pass #1", {"from": accounts[0]})
    two_cnt = gov_proposal.createProposal.transact(
        "fail #2", {"from": accounts[1]})
    three_cnt = gov_proposal.createProposal.transact(
        "pass #3", {"from": accounts[1]})
    four_cnt = gov_proposal.createProposal.transact(
        "fail #4", {"from": accounts[0]})

    print(one_cnt.return_value, two_cnt.return_value,
          three_cnt.return_value, four_cnt.return_value)
    for i in range(11):
        gov_proposal.voteProposal.transact(
            one_cnt.return_value, {"from": accounts[i]})
    for i in range(3, 10):
        gov_proposal.voteProposal.transact(
            three_cnt.return_value, {"from": accounts[i]})
    for i in range(3):
        gov_proposal.voteProposal.transact(
            two_cnt.return_value, {"from": accounts[i]})

    for i in range(4):
        tx_rept = gov_proposal.endProposal.transact(i, {"from": accounts[0]})
        print(tx_rept.return_value)

    tx_rept = gov_proposal.getFinishedProposals.transact({"from": accounts[0]})
    print(tx_rept.return_value)

    time.sleep(1)
    return


def end_term(rep_dao, gov_token):
    """
    start new election and end it. Also verify that proposals are passed
    """
    tx_rept = rep_dao.startElection.transact({"from": accounts[0]})
    gov_election = GovernorVoting.at(str(tx_rept.new_contracts[0]))
    for i in range(20):  # Register all voters
        gov_election.register({"from": accounts[i]})

    for i in range(5, 16):  # Nominate 11 candidates
        gov_election.nominate(accounts[i], {"from": accounts[i]})

    for i in range(20):
        gov_token.approve(gov_election.address, 10**10, {"from": accounts[i]})
        candidate = random.randint(5, 15)
        vote = random.randint(
            0, int(gov_token.balanceOf(accounts[i], {"from": accounts[i]})))
        gov_election.vote(accounts[candidate], vote, {"from": accounts[i]})

    tx_rept = rep_dao.endElection.transact({"from": accounts[0]})
    proposals = rep_dao.getProposals.call({"from": accounts[0]})
    print(proposals)


def impeachments(rep_dao, gov_token):
    tx_rept = rep_dao.startImpeachment.transact(
        accounts[6], {"from": accounts[0]})
    impeach_contract_adddress = tx_rept.new_contracts[0]
    impeach_contract = Impeachment.at(impeach_contract_adddress)
    balances_pre_vote = [gov_token.balanceOf(
        accounts[i], {'from': accounts[i]}) for i in range(20)]
    print(balances_pre_vote)
    for i in range(20):
        gov_token.approve(impeach_contract_adddress,
                          10**10, {"from": accounts[i]})
        impeach_contract.register.transact({"from": accounts[i]})
        impeach_contract.vote.transact(1000, True, {"from": accounts[i]})

    balances_pre_end = [gov_token.balanceOf(
        accounts[i], {'from': accounts[i]}) for i in range(20)]
    print(balances_pre_end)

    tx_rept = rep_dao.endImpeachment.transact({'from': accounts[0]})
    balances_post_end = [gov_token.balanceOf(
        accounts[i], {'from': accounts[i]}) for i in range(20)]
    print(balances_post_end)
    print(tx_rept.return_value)


def main():
    w3 = zero_gas_fees()
    generate_user_accounts()

    rep_dao = RepresentDAO.deploy(
        5, 10, 5, 2, 10**6, 1000, {"from": accounts[0]})
    gov_token = rep_dao.getGovToken.call({"from": accounts[1]})
    gov_token = CitizenToken.at(gov_token)
    airdrop_test(gov_token)
    tx_rept = run_election(rep_dao, gov_token)
    print(tx_rept.return_value)
    gov_proposal = GovernorProposal.at(tx_rept.new_contracts[0])
    governor_proposal_sim(gov_proposal, rep_dao)
    end_term(rep_dao, gov_token)
    impeachments(rep_dao, gov_token)
    time.sleep(1)
