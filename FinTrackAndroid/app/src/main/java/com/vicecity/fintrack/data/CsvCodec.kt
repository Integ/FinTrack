package com.vicecity.fintrack.data

import java.math.BigDecimal
import java.time.LocalDate

object CsvCodec {
    private const val HEADER = "日期,类型,金额,成本,类别,描述"

    fun encode(transactions: List<Transaction>): String = buildString {
        append(HEADER)
        transactions.forEach { transaction ->
            append('\n')
            append(transaction.date)
            append(',')
            append(if (transaction.type == TransactionType.INCOME) "income" else "expense")
            append(',')
            append(transaction.amount.toPlainString())
            append(',')
            if (transaction.type == TransactionType.INCOME) {
                append(transaction.normalizedCost.toPlainString())
            }
            append(',')
            append(escape(transaction.category))
            append(',')
            append(escape(transaction.note))
        }
    }

    fun decode(source: String): List<Transaction> {
        val records = parseRecords(source.removePrefix("\uFEFF"))
            .filterNot { row -> row.all { it.isBlank() } }
        if (records.isEmpty()) return emptyList()

        val headers = records.first().map(String::trim)
        val hasCost = headers.any { it.equals("成本", true) || it.equals("cost", true) } ||
            headers.size > 5

        return records.drop(1).mapIndexed { index, columns ->
            val categoryIndex = if (hasCost) 4 else 3
            val noteIndex = if (hasCost) 5 else 4
            try {
                require(columns.size > noteIndex)
                val type = when (columns[1].trim().lowercase()) {
                    "income", "收入" -> TransactionType.INCOME
                    "expense", "支出" -> TransactionType.EXPENSE
                    else -> error("Unknown transaction type")
                }
                val cost = if (hasCost && columns.size > 3 && columns[3].isNotBlank()) {
                    columns[3].trim().toBigDecimal()
                } else {
                    BigDecimal.ZERO
                }
                Transaction(
                    date = LocalDate.parse(columns[0].trim()),
                    type = type,
                    amount = columns[2].trim().toBigDecimal(),
                    cost = if (type == TransactionType.INCOME) cost else BigDecimal.ZERO,
                    category = columns[categoryIndex].trim(),
                    note = columns[noteIndex].trim(),
                )
            } catch (_: Exception) {
                throw CsvFormatException(index + 2)
            }
        }
    }

    private fun escape(value: String): String = "\"${value.replace("\"", "\"\"")}\""

    internal fun parseRecords(text: String): List<List<String>> {
        val records = mutableListOf<List<String>>()
        var fields = mutableListOf<String>()
        val current = StringBuilder()
        var quoted = false
        var index = 0

        fun finishField() {
            fields += current.toString()
            current.clear()
        }

        fun finishRecord() {
            finishField()
            records += fields
            fields = mutableListOf()
        }

        while (index < text.length) {
            val character = text[index]
            when {
                character == '"' -> {
                    if (quoted && index + 1 < text.length && text[index + 1] == '"') {
                        current.append('"')
                        index++
                    } else {
                        quoted = !quoted
                    }
                }
                character == ',' && !quoted -> finishField()
                (character == '\n' || character == '\r') && !quoted -> {
                    finishRecord()
                    if (character == '\r' && index + 1 < text.length && text[index + 1] == '\n') {
                        index++
                    }
                }
                else -> current.append(character)
            }
            index++
        }
        if (current.isNotEmpty() || fields.isNotEmpty()) finishRecord()
        return records
    }
}

class CsvFormatException(val row: Int) : IllegalArgumentException("CSV row $row is invalid")
