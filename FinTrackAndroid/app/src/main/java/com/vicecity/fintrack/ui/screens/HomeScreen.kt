package com.vicecity.fintrack.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Equalizer
import androidx.compose.material.icons.rounded.SouthWest
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.vicecity.fintrack.FinTrackViewModel
import com.vicecity.fintrack.R
import com.vicecity.fintrack.data.ReportPeriod
import com.vicecity.fintrack.data.Transaction
import com.vicecity.fintrack.ui.components.MetricCard
import com.vicecity.fintrack.ui.components.TransactionRow
import com.vicecity.fintrack.ui.components.formatMoney
import com.vicecity.fintrack.ui.theme.Indigo
import com.vicecity.fintrack.ui.theme.Mint

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    viewModel: FinTrackViewModel,
    contentPadding: PaddingValues,
    onAdd: () -> Unit,
    onEdit: (Transaction) -> Unit,
) {
    val week = viewModel.summary(ReportPeriod.WEEK)
    val today = viewModel.summary(ReportPeriod.TODAY)
    Column(modifier = Modifier.fillMaxSize().padding(bottom = contentPadding.calculateBottomPadding())) {
        CenterAlignedTopAppBar(
            title = { Text(stringResource(R.string.app_name), fontWeight = FontWeight.SemiBold) },
            actions = {
                IconButton(onClick = onAdd) {
                    Icon(Icons.Rounded.Add, contentDescription = stringResource(R.string.add_record))
                }
            },
        )
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(start = 18.dp, end = 18.dp, top = 4.dp, bottom = 100.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            item {
                Card(
                    colors = CardDefaults.cardColors(containerColor = Color.Transparent),
                    shape = RoundedCornerShape(26.dp),
                ) {
                    Column(
                        modifier = Modifier
                            .background(
                                Brush.linearGradient(listOf(Indigo, Color(0xFF5C4FDC)))
                            )
                            .fillMaxWidth()
                            .padding(22.dp),
                        verticalArrangement = Arrangement.spacedBy(17.dp),
                    ) {
                        Text(
                            stringResource(R.string.net_income_last_week),
                            style = MaterialTheme.typography.labelLarge,
                            color = Color.White.copy(alpha = 0.82f),
                        )
                        Text(
                            formatMoney(week.profit, viewModel.currencyChoice),
                            style = MaterialTheme.typography.headlineLarge,
                            fontWeight = FontWeight.Bold,
                            color = Color.White,
                        )
                        Row(horizontalArrangement = Arrangement.spacedBy(28.dp)) {
                            HeroMetric(stringResource(R.string.income), formatMoney(week.income, viewModel.currencyChoice))
                            HeroMetric(stringResource(R.string.total_outflow), formatMoney(week.totalOutflow, viewModel.currencyChoice))
                        }
                    }
                }
            }

            item {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text(stringResource(R.string.today), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        MetricCard(
                            title = stringResource(R.string.business_income),
                            value = formatMoney(today.income, viewModel.currencyChoice),
                            icon = Icons.Rounded.SouthWest,
                            accent = Mint,
                            modifier = Modifier.weight(1f),
                        )
                        MetricCard(
                            title = stringResource(R.string.net_income),
                            value = formatMoney(today.profit, viewModel.currencyChoice),
                            icon = Icons.Rounded.Equalizer,
                            accent = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.weight(1f),
                        )
                    }
                }
            }

            item {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(stringResource(R.string.recent_records), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Text(
                        stringResource(R.string.records_total, viewModel.transactions.size),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            if (viewModel.transactions.isEmpty()) {
                item {
                    Card(shape = RoundedCornerShape(22.dp)) {
                        Column(
                            modifier = Modifier.fillMaxWidth().padding(28.dp),
                            verticalArrangement = Arrangement.spacedBy(10.dp),
                        ) {
                            Text(stringResource(R.string.no_records_yet), style = MaterialTheme.typography.titleMedium)
                            Text(
                                stringResource(R.string.first_record_hint),
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                            Button(onClick = onAdd) { Text(stringResource(R.string.add_first_record)) }
                        }
                    }
                }
            } else {
                item {
                    Card(shape = RoundedCornerShape(22.dp)) {
                        Column {
                            viewModel.transactions.take(4).forEachIndexed { index, transaction ->
                                TransactionRow(
                                    transaction = transaction,
                                    currencyChoice = viewModel.currencyChoice,
                                    onEdit = { onEdit(transaction) },
                                    modifier = Modifier.clickable { onEdit(transaction) },
                                )
                                if (index < minOf(viewModel.transactions.size, 4) - 1) {
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

@Composable
private fun HeroMetric(label: String, value: String) {
    Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(label, style = MaterialTheme.typography.labelSmall, color = Color.White.copy(alpha = 0.65f))
        Text(value, style = MaterialTheme.typography.bodyMedium, color = Color.White, fontWeight = FontWeight.SemiBold)
    }
}
