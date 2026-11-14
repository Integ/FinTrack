"""Generate the production owl icon SVGs. Usage: python3 owl_icon.py [out-dir]"""
from pathlib import Path
import sys


def owl(appearance='light'):
    tinted = appearance == 'tinted'
    dark = appearance == 'dark'
    palette = dict(
        top='#7770F5', bottom='#4934B4', glow='#B4ACFF',
        gold_top='#FFE5A0', gold_bottom='#F4B544', wing='#DB952F',
        face='#FFF8E7', ink='#30264F', beak='#E99538',
        coin='#FFE6A0', rim='#CC8D31', symbol='#86551E',
    )
    if dark:
        palette.update(top='#26223E', bottom='#121121', glow='#655789')
    if tinted:
        palette.update(gold_top='#F2F2F2', gold_bottom='#C9C9C9', wing='#999999',
                       face='#FFFFFF', ink='#292929', beak='#8A8A8A',
                       coin='#E2E2E2', rim='#898989', symbol='#454545')
    p = palette
    background = '' if tinted else '''
  <rect width="1024" height="1024" fill="url(#background)"/>
  <rect width="1024" height="1024" fill="url(#ambient)"/>'''
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="background" x1="0" y1="0" x2="0.85" y2="1">
      <stop stop-color="{p['top']}"/><stop offset="1" stop-color="{p['bottom']}"/>
    </linearGradient>
    <radialGradient id="ambient" cx="0.3" cy="0.15" r="0.85">
      <stop stop-color="{p['glow']}" stop-opacity="0.28"/><stop offset="1" stop-color="{p['glow']}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="plumage" x1="0.2" y1="0" x2="0.75" y2="1">
      <stop stop-color="{p['gold_top']}"/><stop offset="1" stop-color="{p['gold_bottom']}"/>
    </linearGradient>
  </defs>{background}
  <!-- One continuous silhouette: rounded ear tufts stay legible at home-screen size. -->
  <path d="M 226 202 Q 224 171 250 186 L 354 244
           Q 512 196 670 244 L 774 186 Q 800 171 798 202
           L 786 338 Q 828 423 824 552
           C 822 745 706 842 512 842 C 318 842 202 745 200 552
           Q 196 423 238 338 Z" fill="url(#plumage)"/>
  <!-- A single facial mask removes overlapping circles and extra eye rings. -->
  <path d="M 512 378 C 452 285 310 299 278 405
           C 247 509 306 600 402 618 Q 465 632 512 666
           Q 559 632 622 618 C 718 600 777 509 746 405
           C 714 299 572 285 512 378 Z" fill="{p['face']}"/>
  <ellipse cx="397" cy="466" rx="51" ry="60" fill="{p['ink']}"/>
  <ellipse cx="381" cy="445" rx="15" ry="18" fill="{p['face']}"/>
  <path d="M 580 474 Q 630 421 680 474" fill="none" stroke="{p['ink']}" stroke-width="29" stroke-linecap="round"/>
  <path d="M 485 536 Q 512 523 539 536 L 520 571 Q 512 583 504 571 Z" fill="{p['beak']}"/>
  <!-- Coin and folded wings form one clear financial accent. -->
  <circle cx="512" cy="716" r="100" fill="{p['rim']}"/>
  <circle cx="512" cy="708" r="96" fill="{p['coin']}"/>
  <circle cx="512" cy="708" r="76" fill="none" stroke="{p['rim']}" stroke-width="6"/>
  <path d="M 538 674 C 526 659 487 660 485 682
           C 483 707 539 701 539 727 C 539 751 498 755 482 739
           M 512 652 L 512 763" fill="none" stroke="{p['symbol']}" stroke-width="13" stroke-linecap="round"/>
  <path d="M 230 560 C 238 624 275 682 340 704
           C 371 709 409 683 432 700 C 455 723 425 756 391 762
           C 312 772 251 711 230 637 Z" fill="{p['wing']}"/>
  <path d="M 794 560 C 786 624 749 682 684 704
           C 653 709 615 683 592 700 C 569 723 599 756 633 762
           C 712 772 773 711 794 637 Z" fill="{p['wing']}"/>
</svg>
'''


if __name__ == '__main__':
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent
    out.mkdir(parents=True, exist_ok=True)
    for appearance, filename in [('light', 'AppIcon.svg'), ('dark', 'AppIcon-Dark.svg'),
                                 ('tinted', 'AppIcon-Tinted.svg')]:
        (out / filename).write_text(owl(appearance))
