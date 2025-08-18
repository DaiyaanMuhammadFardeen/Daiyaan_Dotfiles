# # Libraries
# import sys

# # Variables
# V       = sys.version_info  # Data type: set
# gBG_bFG = "\033[3;42;30m"   # greenBG_BlackFG
# dBG_gFG = "\033[1;49;32m"   # defaultBG_greenFG
# dBG_dFG = "\033[1;49;39m"
# dBG_pFG = "\033[1;49;35m"
# dBG_yFG = "\033[1;49;33m"
# end     = "\033[0m"
# prompt  = dBG_gFG + " "
# message = f"Python {V[0]}.{V[1]}.{V[2]}"

# # Actual code
# sys.ps1 = "\n"+ dBG_gFG +""+ gBG_bFG + message + dBG_gFG +""+ end +'\n'+ prompt + end
# sys.ps2 = dBG_gFG + " "
