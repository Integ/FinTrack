package com.vicecity.fintrack.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class CsvCodecTest {
    @Test
    fun roundTripPreservesWebCompatibleFields() {
        val original = Transaction(
            date = LocalDate.of(2026, 7, 16),
            type = TransactionType.INCOME,
            amount = "88.50".toBigDecimal(),
            cost = "12.25".toBigDecimal(),
            category = "Shop, weekend",
            note = "Customer said \"great\"",
        )

        val decoded = CsvCodec.decode(CsvCodec.encode(listOf(original))).single()

        assertEquals(original.date, decoded.date)
        assertEquals(original.type, decoded.type)
        assertEquals(0, original.amount.compareTo(decoded.amount))
        assertEquals(0, original.cost.compareTo(decoded.cost))
        assertEquals(original.category, decoded.category)
        assertEquals(original.note, decoded.note)
    }

    @Test
    fun quotedDescriptionMayContainLineBreak() {
        val csv = """
            日期,类型,金额,成本,类别,描述
            2026-07-16,income,42,5,"内容创作","first line
            second line"
        """.trimIndent()

        val transaction = CsvCodec.decode(csv).single()

        assertEquals("first line\nsecond line", transaction.note)
    }

    @Test
    fun oldFormatWithoutCostColumnIsSupported() {
        val csv = "日期,类型,金额,类别,描述\n2026-07-16,支出,18,交通,地铁"
        val transaction = CsvCodec.decode(csv).single()

        assertEquals(TransactionType.EXPENSE, transaction.type)
        assertEquals("交通", transaction.category)
        assertEquals(0, transaction.cost.compareTo(java.math.BigDecimal.ZERO))
    }

    @Test
    fun malformedRowIncludesItsOneBasedFileLine() {
        val error = runCatching {
            CsvCodec.decode("日期,类型,金额,成本,类别,描述\nnot-a-date,income,2,0,x,y")
        }.exceptionOrNull()

        assertTrue(error is CsvFormatException)
        assertEquals(2, (error as CsvFormatException).row)
    }
}
