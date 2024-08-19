#!/usr/bin/env zsh

#####################################
## Test your terminal features
## Used for checking if your terminal supports
## italic, curly-underline, 256 colors, etc
#####################################

echo -e "####################"
echo -e "--- Checking 256 color support (Color should transition smoothly)"
echo -e "####################"
awk 'BEGIN{
    s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
    for (colnum = 0; colnum<77; colnum++) {
        r = 255-(colnum*255/76);
        g = (colnum*510/76);
        b = (colnum*255/76);
        if (g>255) g = 510-g;
        printf "\033[48;2;%d;%d;%dm", r,g,b;
        printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
        printf "%s\033[0m", substr(s,colnum+1,1);
    }
    printf "\n";
}'

echo -e "\n"

echo -e "####################"
echo -e "--- Checking terminal font style support"
echo -e "--- Should loook like this https://askubuntu.com/a/985386/1279765"
echo -e "####################"
echo -e '\e[1mbold\e[22m'
echo -e '\e[2mdim\e[22m'
echo -e '\e[3mitalic\e[23m'
echo -e '\e[4munderline\e[24m'
echo -e '\e[4:1mthis is also underline (since 0.52)\e[4:0m'
echo -e '\e[21mdouble underline (since 0.52)\e[24m'
echo -e '\e[4:2mthis is also double underline (since 0.52)\e[4:0m'
echo -e '\e[4:3mcurly underline (since 0.52)\e[4:0m'
echo -e '\e[4:4mdotted underline (since 0.76)\e[4:0m'
echo -e '\e[4:5mdashed underline (since 0.76)\e[4:0m'
echo -e '\e[7mreverse\e[27m'
echo -e '\e[9mstrikethrough\e[29m'
echo -e '\e[53moverline (since 0.52)\e[55m'

echo -e '\e[31mred\e[39m'
echo -e '\e[91mbright red\e[39m'
echo -e '\e[38:5:42m256-color, de jure standard (ITU-T T.416)\e[39m'
echo -e '\e[38;5;42m256-color, de facto standard (commonly used)\e[39m'
echo -e '\e[38:2::240:143:104mtruecolor, de jure standard (ITU-T T.416) (since 0.52)\e[39m'
echo -e '\e[38:2:240:143:104mtruecolor, rarely used incorrect format (might be removed at some point)\e[39m'
echo -e '\e[38;2;240;143;104mtruecolor, de facto standard (commonly used)\e[39m'

echo -e '\e[46mcyan background\e[49m'
echo -e '\e[106mbright cyan background\e[49m'
echo -e '\e[48:5:42m256-color background, de jure standard (ITU-T T.416)\e[49m'
echo -e '\e[48;5;42m256-color background, de facto standard (commonly used)\e[49m'
echo -e '\e[48:2::240:143:104mtruecolor background, de jure standard (ITU-T T.416) (since 0.52)\e[49m'
echo -e '\e[48:2:240:143:104mtruecolor background, rarely used incorrect format (might be removed at some point)\e[49m'
echo -e '\e[48;2;240;143;104mtruecolor background, de facto standard (commonly used)\e[49m'

echo -e '\e[21m\e[58:5:42m256-color underline (since 0.52)\e[59m\e[24m'
echo -e '\e[21m\e[58;5;42m256-color underline (since 0.52)\e[59m\e[24m'
echo -e '\e[4:3m\e[58:2::240:143:104mtruecolor underline (since 0.52) (*)\e[59m\e[4:0m'
echo -e '\e[4:3m\e[58:2:240:143:104mtruecolor underline (since 0.52) (might be removed at some point) (*)\e[59m\e[4:0m'
echo -e '\e[4:3m\e[58;2;240;143;104mtruecolor underline (since 0.52) (*)\e[59m\e[4:0m'

echo -e '\e[5mblink (since 0.52)\e[25m'
echo -e '\e[8minvisible\e[28m <- invisible (but copy-pasteable)'
