const formatIssues = (err) => err.issues.map((i) => ({ field: i.path.join('.') || 'body', message: i.message }));

function make(source) {
  return (schema) => (req, res, next) => {
    const parsed = schema.safeParse(req[source]);
    if (!parsed.success) {
      return res.status(400).json({ error: 'Datos inválidos', details: formatIssues(parsed.error) });
    }
    if (source === 'query') req.validatedQuery = parsed.data; else req[source] = parsed.data;
    next();
  };
}
module.exports = { validateBody: make('body'), validateParams: make('params'), validateQuery: make('query'), formatIssues };
