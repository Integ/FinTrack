"""Cute owl app icon generator (1024x1024 SVG).

    python3 owl_icon.py <out-dir>      # writes owl_A..D.svg; the app uses concept D

Render to PNG with macOS CoreSVG:
    swiftc -O render_svg.swift -o render_svg && ./render_svg AppIcon.svg AppIcon.png 1024
"""
import sys

def owl(p):
    bg = p['bg']
    body_light, body_mid, body_dark = p['body']
    face = p['face']
    ink = p['ink']
    beak = p['beak']
    parts = []
    add = parts.append
    add('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">')
    add('<defs>')
    if bg:
        add(f'<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{bg[0]}"/><stop offset="1" stop-color="{bg[1]}"/></linearGradient>')
        add('<radialGradient id="glow" cx="0.5" cy="0.45" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="%s"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>' % p.get('glow', 0.18))
    add(f'<radialGradient id="body" cx="0.42" cy="0.3" r="0.8"><stop offset="0" stop-color="{body_light}"/><stop offset="0.55" stop-color="{body_mid}"/><stop offset="1" stop-color="{body_dark}"/></radialGradient>')
    add(f'<linearGradient id="wing" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{body_mid}"/><stop offset="1" stop-color="{body_dark}"/></linearGradient>')
    add('<radialGradient id="coin" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="#FEF9C3"/><stop offset="0.45" stop-color="#FDE047"/><stop offset="1" stop-color="#EAB308"/></radialGradient>')
    add('</defs>')

    if bg:
        add('<rect width="1024" height="1024" fill="url(#bg)"/>')
        add('<circle cx="512" cy="470" r="470" fill="url(#glow)"/>')
        for (x, y, r) in p.get('stars', []):
            add(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#FDE68A" opacity="0.85"/>')
        add('<ellipse cx="512" cy="884" rx="236" ry="30" fill="#000000" opacity="0.18"/>')

    # ear tufts (behind the body)
    left_tuft = 'M 262 318 C 236 252 238 200 250 156 C 300 190 352 228 392 258 Z'
    right_tuft = 'M 762 318 C 788 252 786 200 774 156 C 724 190 672 228 632 258 Z'
    add(f'<path d="{left_tuft}" fill="{body_dark}"/>')
    add(f'<path d="{right_tuft}" fill="{body_dark}"/>')

    # body: one round blob
    add('<path d="M 512 212 C 712 212 818 352 818 548 C 818 752 690 872 512 872 C 334 872 206 752 206 548 C 206 352 312 212 512 212 Z" fill="url(#body)"/>')

    # belly with feather scallops
    add(f'<ellipse cx="512" cy="738" rx="196" ry="128" fill="{face}" opacity="0.92"/>')
    if not p.get('coin'):
        for row, (y, xs) in enumerate([(700, [452, 512, 572]), (752, [422, 482, 542, 602]), (802, [470, 530])]):
            for x in xs:
                add(f'<path d="M {x-20} {y} Q {x} {y+22} {x+20} {y}" stroke="{body_mid}" stroke-width="9" fill="none" stroke-linecap="round" opacity="0.7"/>')

    # wings
    add('<path d="M 226 500 C 182 610 214 766 336 836 C 300 730 304 616 226 500 Z" fill="url(#wing)"/>')
    add('<path d="M 798 500 C 842 610 810 766 688 836 C 724 730 720 616 798 500 Z" fill="url(#wing)"/>')

    # facial discs
    add(f'<circle cx="400" cy="472" r="142" fill="{face}"/>')
    add(f'<circle cx="624" cy="472" r="142" fill="{face}"/>')

    # cheeks
    if p.get('cheeks', True):
        add('<ellipse cx="318" cy="606" rx="44" ry="26" fill="#FB7185" opacity="0.45"/>')
        add('<ellipse cx="706" cy="606" rx="44" ry="26" fill="#FB7185" opacity="0.45"/>')

    def open_eye(cx, cy, look):
        add(f'<circle cx="{cx}" cy="{cy}" r="100" fill="#FFFFFF"/>')
        px, py = cx + look, cy + 10
        add(f'<circle cx="{px}" cy="{py}" r="64" fill="{ink}"/>')
        add(f'<circle cx="{px-22}" cy="{py-24}" r="22" fill="#FFFFFF"/>')
        add(f'<circle cx="{px+20}" cy="{py+18}" r="9" fill="#FFFFFF" opacity="0.9"/>')

    def wink_eye(cx, cy):
        add(f'<path d="M {cx-62} {cy+16} Q {cx} {cy-50} {cx+62} {cy+16}" stroke="{ink}" stroke-width="26" fill="none" stroke-linecap="round"/>')

    open_eye(400, 472, 12)
    if p.get('wink'):
        wink_eye(624, 472)
    else:
        open_eye(624, 472, -12)

    if p.get('glasses'):
        g = p['glasses']
        add(f'<circle cx="400" cy="472" r="116" stroke="{g}" stroke-width="16" fill="none"/>')
        add(f'<circle cx="624" cy="472" r="116" stroke="{g}" stroke-width="16" fill="none"/>')
        add(f'<path d="M 494 432 Q 512 414 530 432" stroke="{g}" stroke-width="14" fill="none" stroke-linecap="round"/>')

    # beak
    add(f'<path d="M 476 556 Q 512 536 548 556 Q 530 600 518 618 Q 512 626 506 618 Q 494 600 476 556 Z" fill="{beak}"/>')
    add('<path d="M 492 556 Q 512 546 532 556" stroke="#FFFFFF" stroke-width="8" fill="none" stroke-linecap="round" opacity="0.45"/>')

    # coin held by the wings
    if p.get('coin'):
        add('<circle cx="512" cy="760" r="96" fill="#CA8A04"/>')
        add('<circle cx="512" cy="752" r="96" fill="url(#coin)"/>')
        add('<circle cx="512" cy="752" r="72" stroke="#CA8A04" stroke-width="8" fill="none" opacity="0.7"/>')
        add('<path d="M 546 714 C 534 698 480 696 478 726 C 476 756 548 748 548 780 C 548 810 488 810 474 790" stroke="#A16207" stroke-width="16" fill="none" stroke-linecap="round"/>')
        add('<path d="M 512 686 L 512 818" stroke="#A16207" stroke-width="14" stroke-linecap="round"/>')
        # wing tips wrapping the coin's edges
        add(f'<ellipse cx="424" cy="772" rx="50" ry="30" transform="rotate(-35 424 772)" fill="{body_dark}"/>')
        add(f'<ellipse cx="600" cy="772" rx="50" ry="30" transform="rotate(35 600 772)" fill="{body_dark}"/>')

    # feet
    for fx in (446, 578):
        for dx in (-22, 0, 22):
            add(f'<ellipse cx="{fx+dx}" cy="{872}" rx="15" ry="19" fill="{p.get("feet", beak)}"/>')

    add('</svg>')
    return '\n'.join(parts)

CONCEPTS = {
    # A: amber owl on the app's indigo — cheerful, high contrast, ties to the gold of the old logo
    'A': dict(bg=('#5B5BF0', '#7C3AED'), body=('#FDE68A', '#FBBF24', '#F59E0B'), face='#FFF7E6',
              ink='#1E1B4B', beak='#F97316', wink=True),
    # B: bookkeeper owl with glasses and a coin, indigo owl on warm cream
    'B': dict(bg=('#FFF7ED', '#FED7AA'), body=('#A5B4FC', '#6366F1', '#4338CA'), face='#EEF2FF',
              ink='#1E1B4B', beak='#F59E0B', glasses='#F59E0B', coin=True, glow=0.5),
    # D: A's amber owl on indigo, winking, holding a gold coin
    'D': dict(bg=('#5B5BF0', '#7C3AED'), body=('#FDE68A', '#FBBF24', '#F59E0B'), face='#FFF7E6',
              ink='#1E1B4B', beak='#F97316', wink=True, coin=True),
    # C: night owl — gold owl on deep navy with stars, closest to the old logo
    'C': dict(bg=('#312E81', '#0F172A'), body=('#FDE68A', '#F59E0B', '#B45309'), face='#FFF3D6',
              ink='#1E1B4B', beak='#EA580C', wink=False, cheeks=True, glow=0.12,
              stars=[(150, 170, 9), (870, 140, 7), (930, 330, 5), (110, 420, 6), (820, 250, 4)]),
}

if __name__ == '__main__':
    out = sys.argv[1]
    for key, params in CONCEPTS.items():
        open(f'{out}/owl_{key}.svg', 'w').write(owl(params))
