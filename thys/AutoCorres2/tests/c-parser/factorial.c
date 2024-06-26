/*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 * Copyright (c) 2022 Apple Inc. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

/** DONT_TRANSLATE */
/** 
  FNSPEC alloc_spec:
  "\<forall>\<sigma> k. \<Gamma> \<turnstile>
    \<lbrace>\<sigma>. (free_pool k)\<^bsup>sep\<^esup> \<rbrace>
    \<acute>ret' :== PROC alloc()
    \<lbrace> ((\<lambda>p s. if k > 0 then (\<turnstile>\<^sub>s p \<and>\<^sup>* \<turnstile>\<^sub>s (p +\<^sub>p 1) \<and>\<^sup>*
        free_pool (k - 1)) s else (free_pool k) s \<and> p = NULL) \<acute>ret')\<^bsup>sep\<^esup> \<rbrace>"
*/

unsigned long *alloc(void)
{
  /* Stub */
}

/** DONT_TRANSLATE */
/** 
  FNSPEC free_spec:
  "\<forall>\<sigma> k. \<Gamma> \<turnstile>
    \<lbrace>\<sigma>. (sep_cut' (ptr_val \<acute>p) (2 * size_of TYPE(machine_word)) \<and>\<^sup>* free_pool k)\<^bsup>sep\<^esup> \<rbrace>
    PROC free(\<acute>p)
    \<lbrace> (free_pool (k + 1))\<^bsup>sep\<^esup> \<rbrace>"
*/

void free(unsigned long *p)
{
  /* Stub */
}


/** FNSPEC factorial_spec:
  "\<forall>\<sigma> k. \<Gamma> \<turnstile>
    \<lbrace>\<sigma>. (free_pool k)\<^bsup>sep\<^esup> \<rbrace>
    \<acute>ret' :== PROC factorial(\<acute>n)
    \<lbrace> if \<acute>ret' \<noteq> NULL then (sep_fac_list \<^bsup>\<sigma>\<^esup>n \<acute>ret' \<and>\<^sup>*
          free_pool (k - (unat \<^bsup>\<sigma>\<^esup>n + 1)))\<^bsup>sep\<^esup> \<and> (unat \<^bsup>\<sigma>\<^esup>n + 1) \<le> k else (free_pool k)\<^bsup>sep\<^esup> \<rbrace>"
*/
unsigned long *factorial(unsigned long n)
{
  unsigned long *p, *q;

  if (n == 0) {
    p = alloc();

    if (!p)
      return 0;

    *p = 1;
    *(p + 1) = 0;

    return p;
  }

  q = factorial(n - 1);

  if (!q)
    return 0;


  p = alloc();


  if (!p) {
    while (q)
      /** INV: "\<lbrace> \<exists>xs. (sep_list xs \<acute>q \<and>\<^sup>* free_pool (k - length xs))\<^bsup>sep\<^esup> \<and>
                   length xs \<le> k \<rbrace>" */
    {
      unsigned long *k = (unsigned long *)*(q + 1);

      free(q);
      q = k;
    }

    return 0;
  }

  *p = n * *q;
  *(p + 1) = (unsigned long)q;

  return p;
}
