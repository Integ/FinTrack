package com.vicecity.fintrack.data

import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.LocalDate

class TransactionSummaryTest {
    @Test
    fun summaryIncludesIncomeCostsAndExpenses() {
        val transactions = listOf(
            transaction(TransactionType.INCOME, "300", "80"),
            transaction(TransactionType.INCOME, "120", "20"),
            transaction(TransactionType.EXPENSE, "35"),
        )

        val summary = transactions.financialSummary()

        assertDecimal("420", summary.income)
        assertDecimal("100", summary.costs)
        assertDecimal("35", summary.expenses)
        assertDecimal("135", summary.totalOutflow)
        assertDecimal("285", summary.profit)
    }

    @Test
    fun expenseNeverUsesAssociatedCost() {
        val transaction = transaction(TransactionType.EXPENSE, "50", "999")
        assertDecimal("0", transaction.normalizedCost)
        assertDecimal("-50", transaction.netAmount)
    }

    @Test
    fun periodIncludesTodayAndPreviousSixDays() {
        val today = LocalDate.of(2026, 8, 5)
        val included = transaction(TransactionType.INCOME, "10", date = today.minusDays(6))
        val excluded = transaction(TransactionType.INCOME, "20", date = today.minusDays(7))

        assertEquals(listOf(included), listOf(included, excluded).inPeriod(ReportPeriod.WEEK, today))
    }

    private fun transaction(
        type: TransactionType,
        amount: String,
        cost: String = "0",
        date: LocalDate = LocalDate.of(2026, 8, 5),
    ) = Transaction(
        date = date,
        type = type,
        amount = amount.toBigDecimal(),
        cost = cost.toBigDecimal(),
        category = "Test",
    )

    private fun assertDecimal(expected: String, actual: BigDecimal) {
        assertEquals(0, expected.toBigDecimal().compareTo(actual))
    }
}
