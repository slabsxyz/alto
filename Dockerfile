# production ready dockerfile that runs pnpm start
FROM node:20.12.2-bullseye

# set working directory
WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    libssl-dev \
    pkg-config \
    git \
    cmake \
    ca-certificates

# Install Rust (required for Foundry)
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV FOUNDRY_BIN="/root/.foundry/bin"
ENV PATH="${FOUNDRY_BIN}:${PATH}"

# Install Foundry tools
RUN foundryup

# install typescript
RUN npm add -g typescript

# copy package.json and pnpm-lock.yaml
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# install pnpm and create global pnpm symlink
RUN corepack install && corepack enable

# copy source code
COPY . .

RUN pnpm fetch

# install dependencies
RUN pnpm install -r

# copy source code
RUN pnpm build

# Expose Anvil port
EXPOSE 8545
EXPOSE 4337

# start 
ENV INFURA_API_KEY=""
CMD ["sh", "-c", "LATEST_BLOCK=$(cast block-number --rpc-url https://sepolia.infura.io/v3/${INFURA_API_KEY}) && echo \"Latest block fetched: $LATEST_BLOCK\" && ./scripts/run-local-instance.sh -f -r https://sepolia.infura.io/v3/${INFURA_API_KEY} -b $LATEST_BLOCK"]