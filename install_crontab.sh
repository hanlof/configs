#!/bin/bash
crontab - << EOF
*/4 * * * * /home/hans/configs/playground/render_moon.sh
EOF
