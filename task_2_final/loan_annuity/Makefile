EXTENSION = loan_annuity
DATA = sql/loan_annuity--1.0.sql

PG_CONFIG = pg_config
DESTDIR ?=
EXTDIR = $(shell $(PG_CONFIG) --sharedir)/extension

install:
	mkdir -p $(DESTDIR)$(EXTDIR)
	cp loan_annuity.control $(DESTDIR)$(EXTDIR)/
	cp $(DATA) $(DESTDIR)$(EXTDIR)/

uninstall:
	rm -f $(DESTDIR)$(EXTDIR)/loan_annuity.control
	rm -f $(DESTDIR)$(EXTDIR)/$(DATA)

.PHONY: install uninstall