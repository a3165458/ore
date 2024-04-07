#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi


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

# 检查并将Solana的路径添加到 .bashrc，如果它还没有被添加
grep -qxF 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc

# 检查并将Cargo的路径添加到 .bashrc，如果它还没有被添加
grep -qxF 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

# 使改动生效
source ~/.bashrc

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

# 检查并将Solana的路径添加到 .bashrc，如果它还没有被添加
grep -qxF 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc

# 检查并将Cargo的路径添加到 .bashrc，如果它还没有被添加
grep -qxF 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

# 使改动生效
source ~/.bashrc


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
if ! ore -V &> /dev/null; then
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


function multiple() {
#!/bin/bash

echo "更新系统软件包..."
sudo apt update && sudo apt upgrade -y
echo "安装必要的工具和依赖..."
sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen
check_and_install_dependencies
    

# 提示用户输入RPC配置地址
read -p "请输入RPC配置地址: " rpc_address

# 用户输入要生成的钱包配置文件数量
read -p "请输入你想要运行的钱包数量: " count

# 用户输入优先费用
read -p "请输入交易的优先费用 (默认设置为 1): " priority_fee
priority_fee=${priority_fee:-1}

# 用户输入线程数
read -p "请输入挖矿时要使用的线程数 (默认设置为 4): " threads
threads=${threads:-4}

# 基础会话名
session_base_name="ore"

# 启动命令模板，使用变量替代rpc地址、优先费用和线程数
start_command_template="while true; do ore --rpc $rpc_address --keypair ~/.config/solana/idX.json --priority-fee $priority_fee mine --threads $threads; echo '进程异常退出，等待重启' >&2; sleep 1; done"

# 确保.solana目录存在
mkdir -p ~/.config/solana

# 循环创建配置文件和启动挖矿进程
for (( i=1; i<=count; i++ ))
do
    # 提示用户输入私钥
    echo "为id${i}.json输入私钥 (格式为包含64个数字的JSON数组):"
    read -p "私钥: " private_key

    # 生成配置文件路径
    config_file=~/.config/solana/id${i}.json

    # 直接将私钥写入配置文件
    echo $private_key > $config_file

    # 检查配置文件是否成功创建
    if [ ! -f $config_file ]; then
        echo "创建id${i}.json失败，请检查私钥是否正确并重试。"
        exit 1
    fi

    # 生成会话名
    session_name="${session_base_name}_${i}"

    # 替换启动命令中的配置文件名和RPC地址
    start_command=${start_command_template//idX/id${i}}

    # 打印开始信息
    echo "开始挖矿，会话名称为 $session_name ..."

    # 使用 screen 在后台启动挖矿进程
    screen -dmS "$session_name" bash -c "$start_command"

    # 打印挖矿进程启动信息
    echo "挖矿进程已在名为 $session_name 的 screen 会话中后台启动。"
    echo "使用 'screen -r $session_name' 命令重新连接到此会话。"
done

}

function check_multiple() {
# 提示用户同时输入起始和结束编号，用空格分隔

# 提示用户输入RPC地址
echo -n "请输入RPC地址（例如 https://api.mainnet-beta.solana.com）: "
read rpc_address

# 提示用户同时输入起始和结束编号，用空格分隔
echo -n "请输入起始和结束编号，中间用空格分隔（例如，对于10个钱包地址，输入1 10）: "
read -a range

# 获取起始和结束编号
start=${range[0]}
end=${range[1]}

# 执行循环
for i in $(seq $start $end); do
  ore --rpc $rpc_address --keypair ~/.config/solana/id$i.json --priority-fee 1 rewards
done


}


function lonely() {

# 提示用户输入RPC配置地址
read -p "请输入RPC配置地址: " rpc_address

# 用户输入要生成的钱包配置文件数量
read -p "请输入你想要运行的钱包数量: " count

# 用户输入优先费用
read -p "请输入交易的优先费用 (默认设置为 1): " priority_fee
priority_fee=${priority_fee:-1}

# 用户输入线程数
read -p "请输入挖矿时要使用的线程数 (默认设置为 4): " threads
threads=${threads:-4}

# 基础会话名
session_base_name="ore"

# 启动命令模板，使用变量替代rpc地址、优先费用和线程数
start_command_template="while true; do ore --rpc $rpc_address --keypair ~/.config/solana/idX.json --priority-fee $priority_fee mine --threads $threads; echo '进程异常退出，等待重启' >&2; sleep 1; done"

# 确保.solana目录存在
mkdir -p ~/.config/solana

# 循环创建配置文件和启动挖矿进程
for (( i=1; i<=count; i++ ))
do
    # 提示用户输入私钥
    echo "为id${i}.json输入私钥 (格式为包含64个数字的JSON数组):"
    read -p "私钥: " private_key

    # 生成配置文件路径
    config_file=~/.config/solana/id${i}.json

    # 直接将私钥写入配置文件
    echo $private_key > $config_file

    # 检查配置文件是否成功创建
    if [ ! -f $config_file ]; then
        echo "创建id${i}.json失败，请检查私钥是否正确并重试。"
        exit 1
    fi

    # 生成会话名
    session_name="${session_base_name}_${i}"

    # 替换启动命令中的配置文件名、RPC地址、优先费用和线程数
    start_command=${start_command_template//idX/id${i}}

    # 打印开始信息
    echo "开始挖矿，会话名称为 $session_name ..."

    # 使用 screen 在后台启动挖矿进程
    screen -dmS "$session_name" bash -c "$start_command"

    # 打印挖矿进程启动信息
    echo "挖矿进程已在名为 $session_name 的 screen 会话中后台启动。"
    echo "使用 'screen -r $session_name' 命令重新连接到此会话。"
done
}

function cliam_multiple() {
#!/bin/bash

# 提示用户输入RPC地址
echo -n "请输入RPC地址（例如：https://api.mainnet-beta.solana.com）: "
read rpc_address

# 确认用户输入的是有效RPC地址
if [[ -z "$rpc_address" ]]; then
  echo "RPC地址不能为空。"
  exit 1
fi

# 提示用户输入优先费用
echo -n "请输入优先费用（单位：lamports，例如：500000）: "
read priority_fee

# 确认用户输入的是有效的数字
if ! [[ "$priority_fee" =~ ^[0-9]+$ ]]; then
  echo "优先费用必须是一个整数。"
  exit 1
fi

# 提示用户同时输入起始和结束编号
echo -n "请输入起始和结束编号，中间用空格分隔比如跑了10个钱包地址，输入1 10即可: "
read -a range

# 获取起始和结束编号
start=${range[0]}
end=${range[1]}

# 无限循环
while true; do
  # 执行循环
  for i in $(seq $start $end); do
    echo "执行钱包 $i 并且RPC $rpc_address and 以及 $priority_fee"
    ore --rpc $rpc_address --keypair ~/.config/solana/id$i.json --priority-fee $priority_fee claim
    
    done
  echo "成功领取 $start to $end."
done

}


function rerun_rpc() {


# 提示用户输入RPC配置地址
read -p "请输入RPC配置地址: " rpc_address

# 用户输入优先费用
read -p "请输入交易的优先费用 (默认设置为 1): " priority_fee
priority_fee=${priority_fee:-1}

# 用户输入线程数
read -p "请输入挖矿时要使用的线程数 (默认设置为 4): " threads
threads=${threads:-4}

# 基础会话名
session_base_name="ore"

# 启动命令模板
start_command_template="while true; do ore --rpc $rpc_address --keypair {} --priority-fee $priority_fee mine --threads $threads; echo '进程异常退出，等待重启' >&2; sleep 1; done"

# 自动查找所有的idn.json文件
config_files=$(find ~/.config/solana -name "id*.json")
for config_file in $config_files
do
    # 使用jq读取文件中的前五个数字，并将它们转换成逗号分隔的字符串
    key_prefix=$(jq -r '.[0:5] | join(",")' "$config_file")

    # 生成会话名
    session_name="${session_base_name}_[${key_prefix}]"

    # 替换启动命令中的配置文件路径
    start_command=$(echo $start_command_template | sed "s|{}|$config_file|g")

    # 打印开始信息
    echo "开始挖矿，会话名称为 $session_name ..."

    # 使用screen在后台启动挖矿进程
    screen -dmS "$session_name" bash -c "$start_command"

    # 打印挖矿进程启动信息
    echo "挖矿进程已在名为 $session_name 的screen会话中后台启动。"
    echo "使用 'screen -r $session_name' 命令重新连接到此会话。"
done


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
        echo "1. 安装新节点（solanakeygen 新建钱包派生有bug，不是非常建议，优先建议是用功能7导入私钥）"
        echo "2. 导入钱包运行"
        echo "3. 单独启动运行"
        echo "4. 单号领取挖矿收益查看挖矿收益"
        echo "5. 单号领取挖矿收益"
        echo "6. 查看节点运行情况"
        echo "7. （适合首次安装）单机多开钱包带安装环境，需要自行准备json私钥"
        echo "8. 单机多开钱包不检查安装环境，需要自行准备json私钥"
        echo "9. 单机多开钱包，查看奖励"
        echo "10. 单机多开钱包，领取奖励（自动轮询）"
        echo "11. 单独更换rpc等配置，并多开自动读取/.config/solana 下所有json私钥文件并且私钥前缀命名监控，请提前安装好jq，不确认安装没，请先执行apt install jq"
        read -p "请输入选项（1-11）: " OPTION

        case $OPTION in
        1) install_node ;;
        2) export_wallet ;;
        3) start ;;
        4) view_rewards ;;
        5) claim_rewards ;;
        6) check_logs ;;
        7) multiple ;;
        8) lonely ;; 
        9) check_multiple ;;
        10) cliam_multiple ;; 
        11) rerun_rpc ;; 
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done
}

# 显示主菜单
main_menu
