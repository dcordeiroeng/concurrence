package com.kotlin.concurrence

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class ConcurrenceApplication

fun main(args: Array<String>) {
	runApplication<ConcurrenceApplication>(*args)
}
