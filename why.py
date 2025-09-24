import os, sys, time, random, shutil

# --- Optional: better ANSI on Windows
try:
    from colorama import just_fix_windows_console  # pip install colorama
    just_fix_windows_console()
except Exception:
    pass

IS_WIN = os.name == "nt"
if IS_WIN:
    import msvcrt

# 16-color hex -> ANSI (foreground/background)
COLOR_MAP_FG = {
    "0":"30","1":"34","2":"32","3":"36","4":"31","5":"35","6":"33","7":"37",
    "8":"90","9":"94","A":"92","B":"96","C":"91","D":"95","E":"93","F":"97"
}
COLOR_MAP_BG = {
    "0":"40","1":"44","2":"42","3":"46","4":"41","5":"45","6":"43","7":"47",
    "8":"100","9":"104","A":"102","B":"106","C":"101","D":"105","E":"103","F":"107"
}

def ask_color(prompt, default):
    try:
        v = input(prompt).strip().upper()[:1]
        if v not in COLOR_MAP_FG: raise ValueError
        return v
    except Exception:
        return default

def get_size():
    cols, rows = shutil.get_terminal_size(fallback=(80, 25))
    # keep a small margin so we don't wrap
    return max(40, cols-1), max(20, rows-1)

def kbhit():
    if IS_WIN:
        return msvcrt.kbhit()
    else:
        # best-effort no-block read on *nix; most likely user is on Windows
        return False

def getch():
    if IS_WIN and msvcrt.kbhit():
        ch = msvcrt.getch()
        try:
            return ch.decode("utf-8", "ignore")
        except Exception:
            return ""
    return ""

def clear_and_hide_cursor():
    sys.stdout.write("\x1b[?25l")  # hide cursor
    sys.stdout.write("\x1b[2J\x1b[H")  # clear + home
    sys.stdout.flush()

def show_cursor_and_reset():
    sys.stdout.write("\x1b[0m\x1b[?25h")
    sys.stdout.flush()

def set_colors(bg_hex, fg_hex):
    bg = COLOR_MAP_BG.get(bg_hex, "40")
    fg = COLOR_MAP_FG.get(fg_hex, "92")  # default light green
    sys.stdout.write(f"\x1b[{bg}m\x1b[{fg}m")
    sys.stdout.flush()

def matrix_rain():
    print("Matrix Rain — choose colors (hex 0–F). Examples: BG=0 (black), FG=A (light green)")
    bg = ask_color("BG (0–F) [default 0]: ", "0")
    fg = ask_color("FG (0–F) [default A]: ", "A")

    cols, rows = get_size()
    clear_and_hide_cursor()
    set_colors(bg, fg)

    chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz*+-=<>/()[]{}"
    rng = random.Random()

    # one drop per column
    drops = [rng.randrange(0, rows) for _ in range(cols)]
    speeds = [rng.choice((1,1,1,2)) for _ in range(cols)]  # mostly 1, some 2
    trail = 10
    delay_ms = 35

    try:
        while True:
            # handle live keys
            if kbhit():
                c = getch().lower()
                if c == "q":
                    break
                elif c == "+":
                    delay_ms = max(5, delay_ms - 5)
                elif c == "-":
                    delay_ms = min(120, delay_ms + 5)
                elif c == "t":
                    trail = min(40, trail + 1)
                elif c == "g":
                    trail = max(1, trail - 1)

            # rebuild frame buffer
            cols, rows = get_size()
            # guard if terminal was resized smaller
            if len(drops) != cols:
                if len(drops) < cols:
                    drops += [rng.randrange(0, rows) for _ in range(cols - len(drops))]
                    speeds += [rng.choice((1,1,1,2)) for _ in range(cols - len(speeds))]
                else:
                    drops = drops[:cols]
                    speeds = speeds[:cols]

            # 2D buffer of spaces
            frame = [bytearray(b" " * cols) for _ in range(rows)]

            # draw each column's head and faint trail
            for x in range(cols):
                head_y = drops[x] % rows
                frame[head_y][x] = ord(chars[rng.randrange(len(chars))])
                for t in range(1, trail + 1):
                    y = head_y - t
                    if y < 0: break
                    # sparsely place trail chars (1 in 3)
                    if rng.randrange(3) == 0:
                        frame[y][x] = ord(chars[rng.randrange(len(chars))])
                drops[x] += speeds[x]
                # occasionally vary speed
                if rng.randrange(100) == 0:
                    speeds[x] = rng.choice((1,1,2))

            # render in-place (cursor home)
            out = ["\x1b[H"]  # home
            for y in range(rows):
                out.append(frame[y].decode("latin1"))
                if y != rows-1:
                    out.append("\n")
            sys.stdout.write("".join(out))
            sys.stdout.flush()

            # sleep
            time.sleep(delay_ms / 1000.0)

    finally:
        show_cursor_and_reset()
        print()  # newline on exit

if __name__ == "__main__":
    matrix_rain()
