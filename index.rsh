'reach 0.1';

const Shared = {
  getNum: Fun([UInt], UInt),
  seeOutcome: Fun([UInt], Null),
}

const amount = 1;

export const main = Reach.App(() => {
  const A = Participant('Alice', {
    // Alice's interact interface
    ...Shared,
    ...hasRandom,
    startRaffle: Fun([], Object({
      nftId: Token,
      numTickets: UInt,
    })),
    seeHash: Fun([Digest], Null),
  });
  const B = Participant('Bob', {    
    //Bob's interact interface
    ...Shared,
    showNum: Fun([UInt], Null),
    seeWinner: Fun([UInt], Null),
  });

  init();

  A.only(() => {
    const { nftId, numTickets} = declassify(interact.startRaffle());
    const _winningNum = interact.getNum(numTickets);
    const [ _commitA, _saltA ] = makeCommitment(interact, _winningNum);
    const commitA = declassify(_commitA);
  })

  // The first participant to publish deploys the contract
  A.publish(nftId, numTickets, commitA);

  A.interact.seeHash(commitA);
  commit();

  A.pay([[amount, nftId]]);
  commit();

  unknowable(B, A(_winningNum, _saltA));

  B.only(() => {
    const myNum = declassify(interact.getNum(numTickets));
    interact.showNum(myNum);
  })

  // The second participant to publish always attaches to the contract
  B.publish(myNum);
  commit();

  A.only(() => {
    const saltA = declassify(_saltA);
    const winningNum = declassify(_winningNum);
  });

  A.publish(saltA, winningNum);
  checkCommitment(commitA, saltA, winningNum);

  B.interact.seeWinner(winningNum);

  const outcome = (myNum == winningNum ? 1: 0);

  transfer(amount, nftId).to(outcome == 0 ? A : B);

  each([A,B], () => {
    interact.seeOutcome(outcome);
  })
  commit();
  exit();
});
