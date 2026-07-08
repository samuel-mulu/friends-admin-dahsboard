import pathlib
import sys

SCREEN_DIR = pathlib.Path('lib/src/features/games/presentation/screens')
SOURCE = SCREEN_DIR / 'live_game_screen.dart'
MIXIN_ON = '_LiveGameScreenStateBase'


def load_source() -> list[str]:
    return SOURCE.read_text(encoding='utf-8').splitlines(keepends=True)


def extract(lines: list[str], start: int, end: int) -> str:
    return ''.join(lines[start - 1 : end])


def join_ranges(lines: list[str], ranges: list[tuple[int, int]]) -> str:
    return ''.join(extract(lines, start, end) for start, end in ranges)


def write_part(path: pathlib.Path, mixin_name: str, body: str, extra: str = '') -> None:
    content = (
        "part of 'live_game_screen.dart';\n\n"
        f'mixin {mixin_name} on {MIXIN_ON} {{\n'
        f'{body}}}\n'
    )
    if extra:
        content += f'\n{extra}'
    path.write_text(content, encoding='utf-8')


def build_main(lines: list[str]) -> str:
    part_declarations = (
        "part 'live_game_realtime.dart';\n"
        "part 'live_game_registration.dart';\n"
        "part 'live_game_called_numbers.dart';\n"
        "part 'live_game_winner_window.dart';\n\n"
    )

    state_base = (
        f'abstract class {MIXIN_ON} extends ConsumerState<LiveGameScreen> {{\n'
        + extract(lines, 50, 91)
        + '}\n\n'
    )

    state_class_open = (
        'class _LiveGameScreenState extends _LiveGameScreenStateBase\n'
        '    with\n'
        '        WidgetsBindingObserver,\n'
        '        LiveGameRealtime,\n'
        '        LiveGameCalledNumbers,\n'
        '        LiveGameWinnerWindow,\n'
        '        LiveGameRegistration {\n'
    )

    return (
        extract(lines, 1, 37)
        + part_declarations
        + extract(lines, 38, 47)
        + '\n'
        + state_base
        + state_class_open
        + extract(lines, 145, 573)
        + '}\n\n'
        + extract(lines, 1979, 2180)
        + extract(lines, 3008, 3033)
        + extract(lines, 3174, 3327)
        + extract(lines, 3359, 3452)
    )


def main() -> int:
    lines = load_source()
    if len(lines) < 3000:
        print(f'Unexpected source length: {len(lines)} lines', file=sys.stderr)
        return 1

    realtime_ranges = [
        (575, 581),
        (583, 702),
        (704, 753),
        (755, 773),
        (775, 794),
        (820, 845),
        (847, 862),
        (864, 909),
        (911, 921),
        (923, 938),
        (940, 980),
        (984, 1088),
        (1090, 1096),
        (1451, 1481),
        (1484, 1523),
        (1526, 1558),
        (1577, 1595),
        (1597, 1615),
    ]

    called_ranges = [
        (90, 144),
        (796, 818),
        (1098, 1123),
        (1125, 1149),
        (1151, 1191),
        (1249, 1284),
        (1617, 1827),
        (1879, 1890),
    ]

    winner_ranges = [
        (1193, 1226),
        (1228, 1247),
        (1286, 1340),
        (1342, 1358),
        (1360, 1419),
        (1421, 1449),
        (1560, 1575),
        (1907, 1976),
    ]

    registration_mixin_ranges = [
        (1829, 1877),
        (1892, 1905),
    ]

    registration_widgets = (
        extract(lines, 2181, 3007)
        + extract(lines, 3034, 3173)
        + extract(lines, 3329, 3357)
    )

    write_part(
        SCREEN_DIR / 'live_game_realtime.dart',
        'LiveGameRealtime',
        join_ranges(lines, realtime_ranges),
    )
    write_part(
        SCREEN_DIR / 'live_game_called_numbers.dart',
        'LiveGameCalledNumbers',
        join_ranges(lines, called_ranges),
    )
    write_part(
        SCREEN_DIR / 'live_game_winner_window.dart',
        'LiveGameWinnerWindow',
        join_ranges(lines, winner_ranges),
    )
    write_part(
        SCREEN_DIR / 'live_game_registration.dart',
        'LiveGameRegistration',
        join_ranges(lines, registration_mixin_ranges),
        registration_widgets,
    )

    SOURCE.write_text(build_main(lines), encoding='utf-8')

    for name in [
        'live_game_screen.dart',
        'live_game_realtime.dart',
        'live_game_called_numbers.dart',
        'live_game_winner_window.dart',
        'live_game_registration.dart',
    ]:
        text = (SCREEN_DIR / name).read_text(encoding='utf-8')
        print(f'{name}: {text.count(chr(10)) + 1} lines')

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
