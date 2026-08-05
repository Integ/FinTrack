package com.vicecity.fintrack.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.vicecity.fintrack.FinTrackViewModel
import com.vicecity.fintrack.R
import com.vicecity.fintrack.data.Transaction
import com.vicecity.fintrack.data.TransactionType
import com.vicecity.fintrack.ui.components.TransactionRow
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

private enum class RecordFilter { ALL, INCOME, EXPENSE }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecordsScreen(
    viewModel: FinTrackViewModel,
    contentPadding: PaddingValues,
    onEdit: (Transaction) -> Unit,
) {
    var filter by remember { mutableStateOf(RecordFilter.ALL) }
    var query by remember { mutableStateOf("") }
    var pendingDelete by remember { mutableStateOf<Transaction?>(null) }

    val filtered = viewModel.transactions.filter { transaction ->
        val matchesType = when (filter) {
            RecordFilter.ALL -> true
            RecordFilter.INCOME -> transaction.type == TransactionType.INCOME
            RecordFilter.EXPENSE -> transaction.type == TransactionType.EXPENSE
        }
        val value = query.trim()
        matchesType && (value.isEmpty() ||
            transaction.category.contains(value, ignoreCase = true) ||
            transaction.note.contains(value, ignoreCase = true))
    }
    val grouped = filtered.groupBy(Transaction::date).toSortedMap(reverseOrder())
    val filters = RecordFilter.entries

    Column(modifier = Modifier.fillMaxSize().padding(bottom = contentPadding.calculateBottomPadding())) {
        CenterAlignedTopAppBar(
            title = { Text(stringResource(R.string.all_records), fontWeight = FontWeight.SemiBold) },
        )
        Column(
            modifier = Modifier.padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            OutlinedTextField(
                value = query,
                onValueChange = { query = it },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                leadingIcon = { Icon(Icons.Rounded.Search, contentDescription = null) },
                placeholder = { Text(stringResource(R.string.search_category_note)) },
                shape = RoundedCornerShape(18.dp),
            )
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                filters.forEachIndexed { index, item ->
                    SegmentedButton(
                        selected = filter == item,
                        onClick = { filter = item },
                        shape = SegmentedButtonDefaults.itemShape(index, filters.size),
                        label = {
                            Text(
                                stringResource(
                                    when (item) {
                                        RecordFilter.ALL -> R.string.all
                                        RecordFilter.INCOME -> R.string.income
                                        RecordFilter.EXPENSE -> R.string.expense
                                    }
                                )
                            )
                        },
                    )
                }
            }
        }

        if (filtered.isEmpty()) {
            Column(
                modifier = Modifier.fillMaxSize().padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Text(stringResource(R.string.no_matching_records), style = MaterialTheme.typography.titleMedium)
                Text(
                    stringResource(R.string.adjust_filters_hint),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 7.dp),
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(15.dp),
            ) {
                grouped.forEach { (date, transactions) ->
                    item(key = date.toString()) {
                        Column(verticalArrangement = Arrangement.spacedBy(7.dp)) {
                            Text(
                                date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG)),
                                style = MaterialTheme.typography.labelLarge,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(start = 12.dp),
                            )
                            Card(shape = RoundedCornerShape(20.dp)) {
                                transactions.forEachIndexed { index, transaction ->
                                    TransactionRow(
                                        transaction = transaction,
                                        currencyChoice = viewModel.currencyChoice,
                                        onEdit = { onEdit(transaction) },
                                        onDelete = { pendingDelete = transaction },
                                        modifier = Modifier.clickable { onEdit(transaction) },
                                    )
                                    if (index != transactions.lastIndex) {
                                        HorizontalDivider(modifier = Modifier.padding(start = 54.dp))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    pendingDelete?.let { transaction ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            title = { Text(stringResource(R.string.delete_record_question)) },
            text = { Text(stringResource(R.string.delete_record_message)) },
            confirmButton = {
                TextButton(onClick = { viewModel.delete(transaction); pendingDelete = null }) {
                    Text(stringResource(R.string.delete), color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { pendingDelete = null }) { Text(stringResource(R.string.cancel)) }
            },
        )
    }
}
