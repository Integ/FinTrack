package com.vicecity.fintrack

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import com.vicecity.fintrack.data.CurrencyChoice
import com.vicecity.fintrack.data.FinancialSummary
import com.vicecity.fintrack.data.ReportPeriod
import com.vicecity.fintrack.data.Transaction
import com.vicecity.fintrack.data.TransactionRepository
import com.vicecity.fintrack.data.dailyTotals
import com.vicecity.fintrack.data.financialSummary
import com.vicecity.fintrack.data.inPeriod

class FinTrackViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = TransactionRepository(application)

    var transactions by mutableStateOf(repository.loadTransactions())
        private set

    var currencyChoice by mutableStateOf(repository.loadCurrencyChoice())
        private set

    fun add(transaction: Transaction) {
        commit(transactions + transaction)
    }

    fun update(transaction: Transaction) {
        commit(transactions.map { if (it.id == transaction.id) transaction else it })
    }

    fun delete(transaction: Transaction) {
        commit(transactions.filterNot { it.id == transaction.id })
    }

    fun replaceAll(imported: List<Transaction>) {
        commit(imported)
    }

    fun append(imported: List<Transaction>) {
        val existingIds = transactions.mapTo(mutableSetOf(), Transaction::id)
        commit(transactions + imported.filterNot { it.id in existingIds })
    }

    fun selectCurrency(choice: CurrencyChoice) {
        currencyChoice = choice
        repository.saveCurrencyChoice(choice)
    }

    fun summary(period: ReportPeriod): FinancialSummary =
        transactions.inPeriod(period).financialSummary()

    fun dailyTotals(period: ReportPeriod) = transactions.dailyTotals(period)

    private fun commit(updated: List<Transaction>) {
        transactions = updated.sortedByDescending(Transaction::date)
        repository.saveTransactions(transactions)
    }
}
