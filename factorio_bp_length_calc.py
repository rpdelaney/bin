#!/usr/bin/env python3
#
"""Quick and dirty calculations for how many times
I can tile a blueprint in factorio before I strip the belt.
"""
import json
from decimal import Decimal, InvalidOperation, getcontext

getcontext().prec = 28

LANE_BLUE_RATE = Decimal("1350")


def main() -> None:
    rates = {}
    while True:
        name = input("Item name (leave blank to finish): ").strip()
        if not name:
            break
        rate_input = input("Rate per minute (decimal safe): ").strip()
        if not rate_input:
            print("Empty rate input. Exiting input loop.")
            break
        try:
            rate = Decimal(rate_input)
            if rate <= 0:
                print("Rate must be a positive number. Please try again.")
                continue
        except InvalidOperation:
            print(
                "Invalid decimal number. Please enter a valid decimal for the rate."
            )
            continue
        rates[name] = rate

    detailed_rates = {}
    for key, rate in rates.items():
        try:
            max_tiles = (LANE_BLUE_RATE / rate).to_integral_value(
                rounding="ROUND_FLOOR"
            )
            max_tiles_int = int(max_tiles)

            detailed_rates[key] = {
                "rate": float(rate),
                "max_tiles_per_lane": max_tiles_int,
                "max_tiles_rate": float(rate * max_tiles),
            }
        except (InvalidOperation, ZeroDivisionError) as e:
            print(f"Error processing item '{key}': {e}. Skipping this item.")
            continue

    if detailed_rates:
        detailed_rates["overall_max_tiles"] = max(
            entry["max_tiles_per_lane"]
            for entry in detailed_rates.values()
        )
    else:
        print("No valid rate entries to compute overall max.")

    print(json.dumps(detailed_rates, indent=2))


if __name__ == "__main__":
    main()

# EOF
