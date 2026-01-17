unsigned int merit = 0;

void credit(unsigned int amount) {
    merit += amount;
}

void debit(unsigned int amount) {
    if (merit >= amount) merit -= amount;
}
