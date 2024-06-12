# 🛣️ Roadmap

## Phase 1: Lumina: Build the multichain infrastructure foundation

First, we built the foundational infrastructure for all LST to be interoperable, used throughout DeFi, and traded in size without slippage.

We built[ standard](https://standardweb3.com/). It is an intent-centric fully decentralized orderbook exchange which does not require any liquidity, and proposed a Uniswap v4 hook that combines both AMM. Thus, no matter how big or small an LST is, it will be able to be traded into other assets. This is the foundation of cross-chain DeFi: DeFi protocols are able to integrate LSTs without LP deposits because they will just trade their assets to counterparties like CEXes.

We built the Omnygram. This is a unified datagram across chains to send intents to execute blockchain transactions. With a relayer client built by the Lumina team, this opens up the true paradigm where all blockchains can interoperate starting from the bottom of the infrastructure to the top application level. Previously if you had ETH, you had to move eth to other chains with prefix on each chain like avaETH. It would just end there otherwise the ticker would go **avapolstarkwtfETH**. Lumina now augments it to one prefix **LumETH**, then moves around across all chains.

From these technologies, Lumina augmenter generates augmented LSTs to teleport them across any chains. Lumina router creates buy/sell order to trade LSTs with near-zero slippage with limit price.&#x20;

## Phase 2: Prisma: LST bridge revolution

Before Lumina, it would be impossible to have thousands of different LSTs across chains. The total liquidity would be fractured across all of these LSTs and depth would be laughably small.

But this unified liquidity layer changes things. There can be thousands, millions of multi-chain LSTs. Each of them can access the full depth of unified liquidity with Lumina Router and Lumina Reserve – without having to put up any liquidity of their own.

So the next step: to launch these LSTs.

We've selected a pioneer batch of six L2 chains to deploy multi chain LSTs: Base, Optimism, Arbitrum, Blast, Zetachain and Neon. These multi-chain LSTs have zero deposit stake fee, zero withdrawal fee, and zero management fee. They therefore represent a strict upgrade over native staking.

The goal is to migrate existing native liquidity from Ethereum to L2 chains, and to get ETH asset holders to hold LSTs instead. These projects are all highly motivated and are excitedly trying different things with their LSTs, and we think that this will kickstart a Cambrian explosion of multi-chain LSTs on Ethereum ecosystem.

## Phase 3: Plethora: Intent based on LSTs

Introducing multi-chain intents starting with cross-chain limit/market order, Intent agents will create a new restaking pool to manage Lumina LST to earn profit with AI technology. Using EigenAVS or other DePin projects to operate agents, developers will be able to create their multichain agents to make their own models to send transactions across chains. The use case would include multichain MEV-agents, HFT trading bots, money market, and so on. Lumina will give sdk for developers to make their own cross-chain app or automated fund operating 24/7. It will host a launchpad to raise money to operate coining a new term “Initial Model Offering(IMO)”.
