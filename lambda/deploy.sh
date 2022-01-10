# ディレクトリ情報の取得
CURRENT_PATH=$(cd $(dirname $0); pwd)

# pythonパッケージのインストール
pip install --target ./notify_slack -r requirements.txt