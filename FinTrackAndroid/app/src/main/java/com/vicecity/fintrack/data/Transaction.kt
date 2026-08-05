package com.vicecity.fintrack.data

import java.math.BigDecimal
import java.math.RoundingMode
import java.time.LocalDate
import java.util.UUID

enum class TransactionType { INCOME, EXPENSE }

data class Transaction(
    val id: String = UUID.randomUUID().toString(),
    val date: LocalDate = LocalDate.now(),
    val type: TransactionType = TransactionType.INCOME,
    val amount: BigDecimal,
    val cost: BigDecimal = BigDecimal.ZERO,
    val category: String,
    val note: String = "",
) {
    val normalizedCost: BigDecimal
        get() = if (type == TransactionType.INCOME) cost else BigDecimal.ZERO

    val netAmount: BigDecimal
        get() = if (type == TransactionType.INCOME) amount - normalizedCost else -amount
}

data class FinancialSummary(
    val income: BigDecimal = BigDecimal.ZERO,
    val costs: BigDecimal = BigDecimal.ZERO,
    val expenses: BigDecimal = BigDecimal.ZERO,
) {
    val totalOutflow: BigDecimal get() = costs + expenses
    val profit: BigDecimal get() = income - totalOutflow
    val profitMargin: BigDecimal
        get() = if (income.compareTo(BigDecimal.ZERO) == 0) {
            BigDecimal.ZERO
        } else {
            profit.divide(income, 6, RoundingMode.HALF_UP)
        }
}

enum class ReportPeriod(val dayCount: Int) {
    TODAY(1), WEEK(7), MONTH(30)
}

data class DailyTotal(
    val date: LocalDate,
    val income: BigDecimal,
    val outflow: BigDecimal,
)

fun Iterable<Transaction>.financialSummary(): FinancialSummary {
    var income = BigDecimal.ZERO
    var costs = BigDecimal.ZERO
    var expenses = BigDecimal.ZERO
    forEach { transaction ->
        when (transaction.type) {
            TransactionType.INCOME -> {
                income += transaction.amount
                costs += transaction.normalizedCost
            }
            TransactionType.EXPENSE -> expenses += transaction.amount
        }
    }
    return FinancialSummary(income, costs, expenses)
}

fun Iterable<Transaction>.inPeriod(
    period: ReportPeriod,
    now: LocalDate = LocalDate.now(),
): List<Transaction> {
    val start = now.minusDays((period.dayCount - 1).toLong())
    return filter { !it.date.isBefore(start) && !it.date.isAfter(now) }
}

fun Iterable<Transaction>.dailyTotals(
    period: ReportPeriod,
    now: LocalDate = LocalDate.now(),
): List<DailyTotal> {
    val transactions = inPeriod(period, now)
    return (period.dayCount - 1 downTo 0).map { daysAgo ->
        val date = now.minusDays(daysAgo.toLong())
        val summary = transactions.filter { it.date == date }.financialSummary()
        DailyTotal(date, summary.income, summary.totalOutflow)
    }
}
