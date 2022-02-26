## 誤って消してしまった GitHub チームのメンバーとリポジトリ設定を復旧する

GitHub のチームを誤って消してしまった場合、復旧方法が機能としては存在しない。
Dec 2017 の Community Forum での回答としても手段がないという回答が確認できる。

https://github.community/t/is-it-possible-to-restore-deleted-team-with-previous-stage/428/2

> Apologies, but there currently isn’t a way to restore a deleted team like you’re asking. You’ll have to recreate the team and re-invite the members to it.

それでもうっかり消してしまい、それが大量のメンバーやリポジトリを抱えるチームだったりするととても困る。
このスクリプトは、GitHub organization の Audit log から可能なかぎり削除したチームの設定を復元することを手伝うものである。

ただ、仕様上の制約から完全に再現をすることはできず、あくまで公式がサポートできないところを埋める補助的なツールの位置付けになることをご了承のうえ、利用してほしい。

## 必要なもの

Audit log がすべての履歴を記録していて、順に辿れば操作を再生できることを前提としている。一定以上古いものなど履歴が欠損している場合、期待通りの動作は得られないので注意してください。

- action:team.add_member action:team.remove_member で Filter した結果の Audit log の Export ファイル (csv)
- team.destroy をきっかけに起きた action:team.remove_repository をリストアップした Audit log の Exrport ファイル (csv)

## 下準備

### Audit log から復旧対象のメンバーとリポジトリのリストを生成する

チームへの参加や退出の履歴を抽出する

    $ tail -n +2 audit_log/export-ORG-members-audit-log.csv | grep team-slug | sort -k7,7 -k4 -t',' | awk -F"," '{print $7 "," $1 "," $4}' > audit_log/members-history.csv

    $ ruby lib/team_member_history.rb members-history.csv 2> errors.log > github-ids

所属していたリポジトリの一覧を出す

    $ grep team-slug audit_log/export-ORG-repository-audit-log.csv | awk -F"," '{print $2 ",push"}' > repositories

",push" のところはリポジトリに設定したい premission を指定する。リポジトリごとに指定したい場合は、出力ファイルから適宜書き換えて指定する。

### OAuth Access Token を登録する

[GitHub 上で OAuth Access Token を発行](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)します。
実際に復旧の操作をするには `admin:org` が必要です。dry run で試行するだけなら、`admin:read` で動きます。

発行したトークンは `.github/credentials` ファイルに記入します。
実行時の <token> の部分には `.github/credentials` の内容にあわせて、使用する OAuth Access Token のキーを指定します。

## 実行

リポジトリの一覧をチームに追加する (dry run)

    ruby lib/restore_team.rb <team-slug> repos repositories <org> <token>

リポジトリの一覧をチームに追加する (実行)

    ruby lib/restore_team.rb <team-slug> repos repositories <org> <token> RUN

チームにアカウントを追加する (dry run)

    ruby lib/restore_team.rb <team-slug> member github-ids <org> <token>

チームにアカウントを追加する (実行)

    ruby lib/restore_team.rb <team-slug> member github-ids <org> <token> RUN

## 注意点

以下の理由ですべてを機械的に解決することはできないが、イレギュラーケース以外の大半のものは機械的に処理していくことができる。

* 同一アカウントで途中で GitHub ID が変わっていることは検出できない
* チーム名が rename されていることは Audit log から一部情報を得ることができるが、変更前の名称については追うことができない
    * GUI からは変更前後の名称を表示して確認することができるが、GUI 上では一定以上古いレコードが表示されない
* 同一名称のチームが作成/削除/再作成されている場合は、 create/destroy から追うことはできるが単一のログでは判断が難しく、操作されたチームがどのチームなのかの同一性を担保していく難易度はやや高い
    * 途中で rename がからむとさらに難易度が上がる

仮に GitHub ID の変更をした後、Organization の参加者ではない別の誰かが変更前の GitHub ID を取得している場合、意図しないアカウントへチームへの参加リクエストが飛ぶ可能性がある (GitHub はかつて他者の使っていた ID を再利用することは仕様上可能)。機械的に招待をしていくことのリスクを認識したうえで十分に注意して使用してください。


