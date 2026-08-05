package com.vicecity.fintrack.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material3.Card
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.vicecity.fintrack.R
import com.vicecity.fintrack.data.CurrencyChoice
import com.vicecity.fintrack.data.Transaction
import com.vicecity.fintrack.data.TransactionType
import com.vicecity.fintrack.ui.components.resolvedCurrencyCode
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Currency
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun TransactionEditor(
    transaction: Transaction?,
    currencyChoice: CurrencyChoice,
    onDismiss: () -> Unit,
    onSave: (Transaction) -> Unit,
) {
    var type by remember(transaction?.id) { mutableStateOf(transaction?.type ?: TransactionType.INCOME) }
    var amountText by remember(transaction?.id) { mutableStateOf(transaction?.amount?.toPlainString().orEmpty()) }
    var costText by remember(transaction?.id) { mutableStateOf(transaction?.normalizedCost?.toPlainString().orEmpty()) }
    var category by remember(transaction?.id) { mutableStateOf(transaction?.category.orEmpty()) }
    var note by remember(transaction?.id) { mutableStateOf(transaction?.note.orEmpty()) }
    var date by remember(transaction?.id) { mutableStateOf(transaction?.date ?: LocalDate.now()) }
    var datePickerVisible by remember { mutableStateOf(false) }

    val amount = amountText.normalizeDecimal().toBigDecimalOrNull()
    val cost = costText.normalizeDecimal().toBigDecimalOrNull() ?: BigDecimal.ZERO
    val canSave = amount != null && amount > BigDecimal.ZERO && category.isNotBlank()
    val other = stringResource(R.string.other)
    val incomeCategories = listOf(
        stringResource(R.string.shop_sales), stringResource(R.string.freelance),
        stringResource(R.string.content_creation), stringResource(R.string.tutoring),
        stringResource(R.string.delivery), other,
    )
    val expenseCategories = listOf(
        stringResource(R.string.inventory), stringResource(R.string.platform_fees),
        stringResource(R.string.transportation), stringResource(R.string.marketing),
        stringResource(R.string.equipment), other,
    )
    val categories = if (type == TransactionType.INCOME) incomeCategories else expenseCategories
    val isCustomCategory = category.isNotBlank() && category !in categories.dropLast(1)
    val currencySymbol = runCatching {
        Currency.getInstance(resolvedCurrencyCode(currencyChoice)).getSymbol(Locale.getDefault())
    }.getOrDefault("¥")

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.surfaceContainerLow) {
            Scaffold(
                topBar = {
                    CenterAlignedTopAppBar(
                        title = {
                            Text(
                                stringResource(if (transaction == null) R.string.add_record else R.string.edit_record),
                                fontWeight = FontWeight.SemiBold,
                            )
                        },
                        navigationIcon = {
                            IconButton(onClick = onDismiss) {
                                Icon(Icons.Rounded.Close, contentDescription = stringResource(R.string.cancel))
                            }
                        },
                        actions = {
                            TextButton(
                                enabled = canSave,
                                onClick = {
                                    onSave(
                                        Transaction(
                                            id = transaction?.id ?: java.util.UUID.randomUUID().toString(),
                                            date = date,
                                            type = type,
                                            amount = amount ?: return@TextButton,
                                            cost = if (type == TransactionType.INCOME) cost else BigDecimal.ZERO,
                                            category = category.trim(),
                                            note = note.trim(),
                                        )
                                    )
                                },
                            ) {
                                Text(stringResource(if (transaction == null) R.string.save else R.string.update), fontWeight = FontWeight.Bold)
                            }
                        },
                    )
                },
            ) { padding ->
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(padding)
                        .verticalScroll(rememberScrollState())
                        .imePadding()
                        .padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(20.dp),
                ) {
                    SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                        TransactionType.entries.forEachIndexed { index, option ->
                            SegmentedButton(
                                selected = type == option,
                                onClick = {
                                    val newCategories = if (option == TransactionType.INCOME) incomeCategories else expenseCategories
                                    type = option
                                    if (option == TransactionType.EXPENSE) costText = ""
                                    if (!isCustomCategory && category !in newCategories) category = ""
                                },
                                shape = SegmentedButtonDefaults.itemShape(index, TransactionType.entries.size),
                                label = { Text(stringResource(if (option == TransactionType.INCOME) R.string.income else R.string.expense)) },
                            )
                        }
                    }

                    Card(shape = RoundedCornerShape(22.dp)) {
                        Column(
                            modifier = Modifier.fillMaxWidth().padding(20.dp),
                            verticalArrangement = Arrangement.spacedBy(14.dp),
                        ) {
                            Text(
                                stringResource(if (type == TransactionType.INCOME) R.string.income_amount_question else R.string.expense_amount_question),
                                fontWeight = FontWeight.SemiBold,
                            )
                            OutlinedTextField(
                                value = amountText,
                                onValueChange = { amountText = it },
                                modifier = Modifier.fillMaxWidth(),
                                prefix = { Text(currencySymbol) },
                                placeholder = { Text("0.00") },
                                textStyle = MaterialTheme.typography.headlineLarge.copy(fontWeight = FontWeight.Bold),
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                                singleLine = true,
                            )
                            if (type == TransactionType.INCOME) {
                                HorizontalDivider()
                                OutlinedTextField(
                                    value = costText,
                                    onValueChange = { costText = it },
                                    modifier = Modifier.fillMaxWidth(),
                                    label = { Text(stringResource(R.string.related_cost_optional)) },
                                    prefix = { Text(currencySymbol) },
                                    placeholder = { Text("0.00") },
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                                    singleLine = true,
                                )
                            }
                        }
                    }

                    Card(shape = RoundedCornerShape(22.dp)) {
                        Column(
                            modifier = Modifier.fillMaxWidth().padding(20.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            Text(stringResource(R.string.category), fontWeight = FontWeight.SemiBold)
                            FlowRow(
                                horizontalArrangement = Arrangement.spacedBy(9.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                categories.forEach { item ->
                                    val selected = if (item == other) isCustomCategory else category == item
                                    FilterChip(
                                        selected = selected,
                                        onClick = { category = if (item == other) category.takeIf { isCustomCategory }.orEmpty() else item },
                                        label = { Text(item) },
                                    )
                                }
                            }
                            if (isCustomCategory || category.isEmpty()) {
                                OutlinedTextField(
                                    value = if (isCustomCategory) category else "",
                                    onValueChange = { category = it },
                                    modifier = Modifier.fillMaxWidth(),
                                    label = { Text(stringResource(R.string.custom_category)) },
                                    singleLine = true,
                                )
                            }
                        }
                    }

                    Card(shape = RoundedCornerShape(22.dp)) {
                        Column(
                            modifier = Modifier.fillMaxWidth().padding(20.dp),
                            verticalArrangement = Arrangement.spacedBy(14.dp),
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween,
                            ) {
                                Text(stringResource(R.string.date), fontWeight = FontWeight.SemiBold)
                                OutlinedButton(onClick = { datePickerVisible = true }) {
                                    Text(date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM)))
                                }
                            }
                            HorizontalDivider()
                            OutlinedTextField(
                                value = note,
                                onValueChange = { note = it },
                                modifier = Modifier.fillMaxWidth(),
                                label = { Text(stringResource(R.string.note)) },
                                placeholder = { Text(stringResource(R.string.note_hint)) },
                                minLines = 2,
                                maxLines = 4,
                            )
                        }
                    }
                }
            }
        }
    }

    if (datePickerVisible) {
        val pickerState = rememberDatePickerState(
            initialSelectedDateMillis = date.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
        )
        DatePickerDialog(
            onDismissRequest = { datePickerVisible = false },
            confirmButton = {
                TextButton(onClick = {
                    pickerState.selectedDateMillis?.let { millis ->
                        date = Instant.ofEpochMilli(millis).atZone(ZoneOffset.UTC).toLocalDate()
                    }
                    datePickerVisible = false
                }) { Text(stringResource(R.string.ok)) }
            },
            dismissButton = {
                TextButton(onClick = { datePickerVisible = false }) { Text(stringResource(R.string.cancel)) }
            },
        ) {
            DatePicker(state = pickerState)
        }
    }
}

private fun String.normalizeDecimal(): String = replace(',', '.').trim()
