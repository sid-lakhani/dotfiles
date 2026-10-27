function fish_greeting
    echo -ne '\x1b[38;5;16m' # Set colour to primary
    echo '    _____ _     __                             __  '
    echo '   / ___/(_)___/ /____        ____ ___________/ /_ '
    echo '   \__ \/ / __  / ___/______ / __ `/ ___/ ___/ __ \\'
    echo '  ___/ / / /_/ (__  )_______/ /_/ / /  / /__/ / / /'
    echo ' /____/_/\__,_/____/        \__,_/_/   \___/_/ /_/ '
    echo ''
    set_color normal
    command -v fastfetch &> /dev/null && fastfetch --key-padding-left 5
end
