# -river.0.4.0-dev
A non-monolithic Wayland compositor


Tips: 如果发现某些脚本类型的文件中的功能没反应，回头查看脚本是否有用户的执行权限，没有就打开终端输入命令 `chmod +x 脚本文件的绝对路径`


在Archlinux系统安装river的最佳方式：用一个directory包住这个仓库里的PKGBUILD文件然后进入这个directory执行`makepkg -si`。 


这样的好处是：这是最“Arch”的方式。通过 makepkg 构建一个安装包，pacman 就能像管理官方软件一样管理你的自定义版本。


用 PKGBUILD 是最完美的方案。因为它能让你在“享受自定义源码”的同时，依然通过 pacman 进行纯净的卸载和管理。


当你使用 makepkg -si 时，系统里会发生这些事：

    沙盒编译：所有的编译过程都在一个临时文件夹内完成。

    生成安装包：你会得到一个 .pkg.tar.zst 文件。

    受控安装：pacman 知道这个包里每一个文件（二进制文件、手册页）的具体位置。

如果你以后想卸载： 只需要执行 sudo pacman -Rs river-git(因为PKGBUILD文件里的pkgname为准)，所有东西会消失得干干净净，不会在 /usr/bin 留下任何无主文件。
以后如何更新配置？

    编辑这个PKGBUILD文件，看有没有source部分需要更新一下。

    再次运行 makepkg -si。

    pacman 会检测新版本，并询问你是否要“重新安装（覆盖）”。选“是”即可。

为什么这个逻辑很高级？

    如果你直接执行 sudo make install：

        文件会散落在 /usr/bin、/usr/share 各处。

        一旦你想卸载，你得手动去一个个找，找不干净系统就“脏”了。

    如果你通过 PKGBUILD：

        Pacman 拥有一份“清单”：它准确知道这个包往 /usr/bin 放了哪个文件。

        一键回滚：当你执行 pacman -R，它只需对着清单把文件擦掉即可，绝对不会误伤系统。
