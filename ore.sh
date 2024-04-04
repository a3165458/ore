#!/bin/bash


function install_node() {

# 更新系统和安装必要的包
echo "更新系统软件包..."
sudo apt update && sudo apt upgrade -y
echo "安装必要的工具和依赖..."
sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen

# 安装 Rust 和 Cargo
echo "正在安装 Rust 和 Cargo..."
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env

# 安装 Solana CLI
echo "正在安装 Solana CLI..."
sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"

# 检查 solana-keygen 是否在 PATH 中
if ! command -v solana-keygen &> /dev/null; then
    echo "将 Solana CLI 添加到 PATH"
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# 创建 Solana 密钥对
echo "正在创建 Solana 密钥对..."
solana-keygen new --derivation-path m/44'/501'/0'/0' --force | tee solana-keygen-output.txt

# 显示提示信息，要求用户确认已备份
echo "请确保你已经备份了上面显示的助记词和私钥信息。"
echo "请向pubkey充值sol资产，用于挖矿gas费用。"

echo "备份完成后，请输入 'yes' 继续："

read -p "" user_confirmation

if [[ "$user_confirmation" == "yes" ]]; then
    echo "确认备份。继续执行脚本..."
else
    echo "脚本终止。请确保备份你的信息后再运行脚本。"
    exit 1
fi

# 安装 Ore CLI
echo "正在安装 Ore CLI..."
cargo install ore-cli

# 获取用户输入的 RPC 地址或使用默认地址
read -p "请输入自定义的 RPC 地址，建议使用免费的Quicknode 或者alchemy SOL rpc(默认设置使用 https://api.mainnet-beta.solana.com): " custom_rpc
RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

# 获取用户输入的线程数或使用默认值
read -p "请输入挖矿时要使用的线程数 (默认设置 4): " custom_threads
THREADS=${custom_threads:-4}

# 获取用户输入的优先费用或使用默认值
read -p "请输入交易的优先费用 (默认设置 1): " custom_priority_fee
PRIORITY_FEE=${custom_priority_fee:-1}

# 使用 screen 和 Ore CLI 开始挖矿
session_name="ore"
echo "开始挖矿，会话名称为 $session_name ..."

start="while true; do ore --rpc $RPC_URL --keypair ~/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo '进程异常退出，等待重启' >&2; sleep 1; done"
screen -dmS "$session_name" bash -c "$start"

echo "挖矿进程已在名为 $session_name 的 screen 会话中后台启动。"
echo "使用 'screen -r $session_name' 命令重新连接到此会话。"

}

# 查看节点同步状态
# 恢复Solana钱包并开始挖矿
function export_wallet() {
    # 更新系统和安装必要的包
    echo "更新系统软件包..."
    sudo apt update && sudo apt upgrade -y
    echo "安装必要的工具和依赖..."
    sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen
    check_and_install_dependencies
    
    echo "正在恢复Solana钱包..."
    # 提示用户输入助记词
    echo "下方请粘贴/输入你的助记词，用空格分隔，盲文不会显示的"

    # 使用助记词恢复钱包
    solana-keygen recover 'prompt:?key=0/0' --force

    echo "钱包已恢复。"
    echo "请确保你的钱包地址已经充足的 SOL 用于交易费用。"


    # 获取用户输入的 RPC 地址或使用默认地址
    read -p "请输入自定义的 RPC 地址，建议使用免费的Quicknode 或者alchemy SOL rpc(默认设置使用 https://api.mainnet-beta.solana.com): " custom_rpc
    RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

    # 获取用户输入的线程数或使用默认值
    read -p "请输入挖矿时要使用的线程数 (默认设置 4): " custom_threads
    THREADS=${custom_threads:-4}

    # 获取用户输入的优先费用或使用默认值
    read -p "请输入交易的优先费用 (默认设置 1): " custom_priority_fee
    PRIORITY_FEE=${custom_priority_fee:-1}

    # 使用 screen 和 Ore CLI 开始挖矿
    session_name="ore"
    echo "开始挖矿，会话名称为 $session_name ..."

    start="while true; do ore --rpc $RPC_URL --keypair root/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo '进程异常退出，等待重启' >&2; sleep 1; done"
    screen -dmS "$session_name" bash -c "$start"

    echo "挖矿进程已在名为 $session_name 的 screen 会话中后台启动。"
    echo "使用 'screen -r $session_name' 命令重新连接到此会话。"
}

function check_and_install_dependencies() {
    # 检查是否已安装 Rust 和 Cargo
    if ! command -v cargo &> /dev/null; then
        echo "Rust 和 Cargo 未安装，正在安装..."
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        source $HOME/.cargo/env
    else
        echo "Rust 和 Cargo 已安装。"
    fi

    # 检查是否已安装 Solana CLI
    if ! command -v solana-keygen &> /dev/null; then
        echo "Solana CLI 未安装，正在安装..."
        sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"
    else
        echo "Solana CLI 已安装。"
    fi

    # 检查是否已安装 Ore CLI
    if ! cargo install ore-cli --version | grep ore-cli &> /dev/null; then
        echo "Ore CLI 未安装，正在安装..."
        cargo install ore-cli
    else
        echo "Ore CLI 已安装。"
    fi

        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        export PATH="$HOME/.cargo/bin:$PATH"
}

function start() {
# 获取用户输入的 RPC 地址或使用默认地址
read -p "请输入自定义的 RPC 地址，建议使用免费的Quicknode 或者alchemy SOL rpc(默认设置使用 https://api.mainnet-beta.solana.com): " custom_rpc
RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

# 获取用户输入的线程数或使用默认值
read -p "请输入挖矿时要使用的线程数 (默认设置 4): " custom_threads
THREADS=${custom_threads:-4}

# 获取用户输入的优先费用或使用默认值
read -p "请输入交易的优先费用 (默认设置 1): " custom_priority_fee
PRIORITY_FEE=${custom_priority_fee:-1}

# 使用 screen 和 Ore CLI 开始挖矿
session_name="ore"
echo "开始挖矿，会话名称为 $session_name ..."

start="while true; do ore --rpc $RPC_URL --keypair ~/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo '进程异常退出，等待重启' >&2; sleep 1; done"
screen -dmS "$session_name" bash -c "$start"

echo "挖矿进程已在名为 $session_name 的 screen 会话中后台启动。"
echo "使用 'screen -r $session_name' 命令重新连接到此会话。"

}


# 查询奖励
function view_rewards() {
    ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id.json rewards
}

# 领取奖励
function claim_rewards() {
    ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id.json claim
}


function check_logs() {
    screen -r ore
}



# 主菜单
function main_menu() {
    while true; do
        clear
        echo "脚本以及教程由推特用户大赌哥 @y95277777 编写，免费开源，请勿相信收费"
        echo "================================================================"
        echo "节点社区 Telegram 群组:https://t.me/niuwuriji"
        echo "节点社区 Telegram 频道:https://t.me/niuwuriji"
        echo "退出脚本，请按键盘ctrl c退出即可"
        echo "请选择要执行的操作:"
        echo "1. 安装新节点"
        echo "2. 导入钱包运行"
        echo "3. 单独启动运行"
        echo "4. 查看挖矿收益"
        echo "5. 领取挖矿收益"
        echo "6. 查看节点运行情况"
        read -p "请输入选项（1-6）: " OPTION

        case $OPTION in
        1) install_node ;;
        2) export_wallet ;;
        3) start ;;
        4) view_rewards ;;
        5) claim_rewards ;;
        6) check_logs ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done
}

# 显示主菜单
main_menu
