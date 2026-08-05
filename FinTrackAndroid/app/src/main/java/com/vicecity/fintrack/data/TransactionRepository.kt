package com.vicecity.fintrack.data

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.math.BigDecimal
import java.time.LocalDate

class TransactionRepository(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)

    fun loadTransactions(): List<Transaction> = runCatching {
        val source = preferences.getString(KEY_TRANSACTIONS, null) ?: return emptyList()
        val array = JSONArray(source)
        buildList {
            repeat(array.length()) { index ->
                val item = array.getJSONObject(index)
                add(
                    Transaction(
                        id = item.getString("id"),
                        date = LocalDate.parse(item.getString("date")),
                        type = TransactionType.valueOf(item.getString("type")),
                        amount = item.getString("amount").toBigDecimal(),
                        cost = item.optString("cost", "0").toBigDecimal(),
                        category = item.getString("category"),
                        note = item.optString("note", ""),
                    )
                )
            }
        }.sortedByDescending(Transaction::date)
    }.getOrDefault(emptyList())

    fun saveTransactions(transactions: List<Transaction>) {
        val array = JSONArray()
        transactions.forEach { transaction ->
            array.put(
                JSONObject()
                    .put("id", transaction.id)
                    .put("date", transaction.date.toString())
                    .put("type", transaction.type.name)
                    .put("amount", transaction.amount.toPlainString())
                    .put("cost", transaction.normalizedCost.toPlainString())
                    .put("category", transaction.category)
                    .put("note", transaction.note)
            )
        }
        preferences.edit().putString(KEY_TRANSACTIONS, array.toString()).apply()
    }

    fun loadCurrencyChoice(): CurrencyChoice {
        val stored = preferences.getString(KEY_CURRENCY, CurrencyChoice.SYSTEM.name)
        return runCatching { CurrencyChoice.valueOf(stored.orEmpty()) }.getOrDefault(CurrencyChoice.SYSTEM)
    }

    fun saveCurrencyChoice(choice: CurrencyChoice) {
        preferences.edit().putString(KEY_CURRENCY, choice.name).apply()
    }

    private companion object {
        const val PREFERENCES_NAME = "fintrack_preferences"
        const val KEY_TRANSACTIONS = "transactions"
        const val KEY_CURRENCY = "currency"
    }
}

enum class CurrencyChoice(val code: String?) {
    SYSTEM(null), CNY("CNY"), USD("USD"), CAD("CAD"), EUR("EUR")
}
