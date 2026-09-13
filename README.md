# PriceTrack

Scan grocery receipts, itemise them, and see which store (Aldi, Coles, Woolworths, Costco) is actually cheapest per item — by unit price, not just sticker price. Favourite the items you care about (A2 milk, eggs, etc.) to keep them front and centre.

<p>
  <img src="screenshots/all-items.png" width="260" alt="All Items list with category filters and colour-coded categories">
  <img src="screenshots/favorites.png" width="260" alt="Favourites tab with per-store price comparison">
  <img src="screenshots/item-detail.png" width="260" alt="Item detail with price history chart">
</p>

*(Screenshots use fictional sample data, not real receipts.)*

## How it works

- **Scan tab** — capture a receipt with the camera (or pick an existing photo), on-device Vision OCR reads the text, and you tap each line to assign it to an item, price, quantity, and unit. This is deliberately "OCR + confirm" rather than fully automatic, since receipt layouts vary a lot between stores and blind parsing gets it wrong often enough to be annoying.
- **Favourites tab** — your starred items, each showing the cheapest current store (by unit price) with the other stores for comparison.
- **All Items tab** — every item you've ever logged, searchable and filterable by category (auto-suggested from the item name via keyword matching, always editable). Swipe to favourite/delete a single item, or tap *Select* for multi-select delete.
- **Item detail** — full per-store comparison, price history chart over time, and the raw list of logged prices (swipe to delete). You can also log a price manually here without scanning anything.
